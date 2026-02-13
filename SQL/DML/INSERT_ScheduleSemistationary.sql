USE master;
GO

-- Валидация входных параметров
CREATE OR ALTER PROCEDURE dbo.sp_InsertScheduleSemistacionar
    @group_id INT,
    @discipline_id SMALLINT,
    @teacher_id INT,
    @start_date DATE = NULL,
    @end_date DATE,
    @weekday TINYINT = NULL,
    @time TIME,
    @subject NVARCHAR(256) = NULL,
    @frequency_weeks TINYINT = 1,
    @max_rows INT = 1000
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Валидация входных данных
    IF @group_id IS NULL
    BEGIN
        PRINT 'Parameter @group_id is required.'; RETURN -1;
    END
    IF @end_date IS NULL
    BEGIN
        PRINT 'Parameter @end_date is required.'; RETURN -1;
    END
    IF @frequency_weeks < 1
    BEGIN
        PRINT 'Parameter @frequency_weeks must be >= 1.'; RETURN -1;
    END
    IF @weekday IS NOT NULL AND (@weekday < 1 OR @weekday > 7)
    BEGIN
        PRINT 'Parameter @weekday must be in range 1..7 or NULL.'; RETURN -1;
    END

    -- Получение метаданных группы
    DECLARE @group_name NVARCHAR(50) = NULL;
    DECLARE @group_start DATE = NULL;
    DECLARE @group_weekdays BIGINT = NULL; -- Маска: bit0=Mon ... bit6=Sun
    DECLARE @group_table NVARCHAR(50) = NULL;

    IF OBJECT_ID('master.dbo.Groups', 'U') IS NOT NULL
    BEGIN
        SELECT TOP (1) @group_name = group_name, @group_start = TRY_CAST(start_date AS DATE)
        FROM master.dbo.Groups WHERE group_id = @group_id;
        IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('master.dbo.Groups') AND name = 'weekdays')
            SELECT @group_weekdays = TRY_CAST(weekdays AS BIGINT) FROM master.dbo.Groups WHERE group_id = @group_id;
        SET @group_table = 'Groups';
    END

    IF @group_name IS NULL AND OBJECT_ID('master.dbo.[Group]', 'U') IS NOT NULL
    BEGIN
        SELECT TOP (1) @group_name = group_name, @group_start = TRY_CAST(start_date AS DATE)
        FROM master.dbo.[Group] WHERE group_id = @group_id;
        IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('master.dbo.[Group]') AND name = 'weekdays')
            SELECT @group_weekdays = TRY_CAST(weekdays AS BIGINT) FROM master.dbo.[Group] WHERE group_id = @group_id;
        SET @group_table = 'Group';
    END

    IF @group_name IS NULL
    BEGIN
        PRINT FORMATMESSAGE('Group with id %d not found.', @group_id); RETURN -1;
    END

    -- Определение начальной даты
    IF @start_date IS NULL
    BEGIN
        IF OBJECT_ID('dbo.GetStartDate', 'FN') IS NOT NULL
        BEGIN
            BEGIN TRY SET @start_date = dbo.GetStartDate(@group_name); END TRY BEGIN CATCH SET @start_date = NULL; END CATCH
        END
        IF @start_date IS NULL SET @start_date = COALESCE(@group_start, CAST(GETDATE() AS DATE));
    END

    -- Выравнивание на первый подходящий день
    DECLARE @first DATE = @start_date;
    IF @weekday IS NOT NULL
    BEGIN
        DECLARE @offset INT = (@weekday - DATEPART(WEEKDAY, @first) + 7) % 7;
        SET @first = DATEADD(DAY, @offset, @first);
    END
    ELSE
    BEGIN
        IF @group_weekdays IS NOT NULL
        BEGIN
            DECLARE @tries INT = 0;
            WHILE @tries < 14 AND @first <= @end_date
            BEGIN
                DECLARE @iso_wd TINYINT = ((DATEPART(WEEKDAY, @first) + @@DATEFIRST - 2) % 7) + 1;
                DECLARE @bit BIGINT = CAST(POWER(CONVERT(FLOAT,2), @iso_wd - 1) AS BIGINT);
                IF (@group_weekdays & @bit) <> 0 BREAK;
                SET @first = DATEADD(DAY, 1, @first);
                SET @tries = @tries + 1;
            END
            IF @tries >= 14 SET @first = @start_date;
        END
    END

    IF @first > @end_date
    BEGIN
        PRINT 'No matching dates in range.'; RETURN 0;
    END

    -- Оценка количества кандидатов
    DECLARE @days INT = DATEDIFF(DAY, @first, @end_date);
    DECLARE @occurrences_est INT = (@days / (7 * @frequency_weeks)) + 1;
    IF @occurrences_est <= 0 BEGIN PRINT 'No occurrences calculated.'; RETURN 0; END
    IF @occurrences_est > @max_rows BEGIN PRINT FORMATMESSAGE('Operation would generate %d candidate dates which exceeds @max_rows (%d).', @occurrences_est, @max_rows); RETURN -1; END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Сгенерировать кандидатов
        CREATE TABLE #Candidates (LessonDate DATE PRIMARY KEY);

        ;WITH
        E(n) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
        E2(n) AS (SELECT 1 FROM E a CROSS JOIN E b),
        E4(n) AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) - 1 AS n FROM E2 CROSS JOIN E2)
        INSERT INTO #Candidates (LessonDate)
        SELECT DATEADD(DAY, n * (7 * @frequency_weeks), @first) AS LessonDate
        FROM E4
        WHERE n < @occurrences_est
          AND DATEADD(DAY, n * (7 * @frequency_weeks), @first) <= @end_date;

        -- Удалить кандидаты, попадающие на праздники. Использовать централизованную логику dbo.IsHoliday если она доступна.
        IF OBJECT_ID('dbo.IsHoliday', 'FN') IS NOT NULL
        BEGIN
            DELETE FROM #Candidates WHERE dbo.IsHoliday(LessonDate) = 1;
        END
        ELSE
        BEGIN
            -- Фоллбек: если dbo.IsHoliday отсутствует, попытаться удалить по распространённым таблицам праздников.
            DECLARE @hol_table NVARCHAR(128) = NULL;
            DECLARE @hol_table_q NVARCHAR(256) = NULL;
            DECLARE @hol_col NVARCHAR(128) = NULL;
            IF OBJECT_ID('master.dbo.Holidays','U') IS NOT NULL SET @hol_table = 'Holidays';
            ELSE IF OBJECT_ID('master.dbo.HolidayDates','U') IS NOT NULL SET @hol_table = 'HolidayDates';
            ELSE IF OBJECT_ID('master.dbo.AcademicHolidays','U') IS NOT NULL SET @hol_table = 'AcademicHolidays';

            IF @hol_table IS NOT NULL
            BEGIN
                SET @hol_table_q = 'master.dbo.' + QUOTENAME(@hol_table);
                SELECT TOP (1) @hol_col = name
                FROM master.sys.columns
                WHERE object_id = OBJECT_ID(@hol_table_q)
                  AND (
                        LOWER(name) IN ('holiday_date','date','hd_date','hdate','holidayday','day','holiday')
                        OR TYPE_NAME(user_type_id) LIKE '%date%'
                      )
                ORDER BY CASE WHEN LOWER(name) IN ('holiday_date','date') THEN 0 ELSE 1 END;
            END

            IF @hol_table IS NOT NULL AND @hol_col IS NOT NULL
            BEGIN
                DECLARE @sql NVARCHAR(MAX) = N'
                    DELETE c
                    FROM #Candidates c
                    JOIN ' + @hol_table_q + ' h ON CONVERT(DATE, h.' + QUOTENAME(@hol_col) + ') = c.LessonDate;
                ';
                EXEC sp_executesql @sql;
            END
        END

        -- Удалить кандидаты, которые уже есть в расписании
        DELETE c
        FROM #Candidates c
        WHERE EXISTS (
            SELECT 1 FROM master.dbo.Schedule s
            WHERE s.[group] = @group_id
              AND s.discipline = @discipline_id
              AND s.[time] = @time
              AND s.[date] = c.LessonDate
        );

        DECLARE @to_insert INT;
        SELECT @to_insert = COUNT(*) FROM #Candidates;
        IF @to_insert = 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'No new schedule rows to insert (all candidates already exist or are holidays).';
            RETURN 0;
        END
        IF @to_insert > @max_rows
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT FORMATMESSAGE('After filtering, %d rows would be inserted which exceeds @max_rows (%d). Aborting.', @to_insert, @max_rows);
            RETURN -1;
        END

        -- Вставка строк расписания
        INSERT INTO master.dbo.Schedule ([date], [time], [group], discipline, teacher, spent, [subject])
        SELECT LessonDate, @time, @group_id, @discipline_id, @teacher_id, 0, @subject
        FROM #Candidates
        ORDER BY LessonDate;

        DECLARE @Inserted INT = @@ROWCOUNT;
        COMMIT TRANSACTION;

        PRINT FORMATMESSAGE('Inserted %d rows into Schedule.', @Inserted);
        SELECT @Inserted AS InsertedRows; RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE(); DECLARE @ErrNum INT = ERROR_NUMBER();
        PRINT FORMATMESSAGE('Error in sp_InsertScheduleSemistacionar (Err=%d): %s', @ErrNum, @ErrMsg);
        RETURN -1;
    END CATCH
END
GO

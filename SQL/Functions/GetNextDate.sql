USE master;
GO

-- Возвращает следующую дату занятия для группы с учётом расписания, рабочих дней и праздников.
CREATE OR ALTER FUNCTION dbo.GetNextDate(@group_name NVARCHAR(24))
RETURNS DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @group_id INT = NULL;
    DECLARE @group_start DATE = NULL;
    DECLARE @weekdays_mask BIGINT = NULL; -- Битовая маска: bit0=Mon ... bit6=Sun
    DECLARE @last_date DATE = NULL;
    DECLARE @search_start DATE = NULL;
    DECLARE @candidate DATE = NULL;
    DECLARE @limit DATE = NULL;
    DECLARE @result DATE = NULL;

    -- Получить метаданные группы из Groups
    IF OBJECT_ID('master.dbo.Groups', 'U') IS NOT NULL
    BEGIN
        SELECT TOP (1)
            @group_id = TRY_CAST(group_id AS INT),
            @group_start = TRY_CAST(start_date AS DATE),
            @weekdays_mask = TRY_CAST(weekdays AS BIGINT)
        FROM master.dbo.Groups
        WHERE group_name = @group_name;
    END

    -- Пробовать legacy [Group]
    IF @group_id IS NULL AND OBJECT_ID('master.dbo.[Group]', 'U') IS NOT NULL
    BEGIN
        SELECT TOP (1)
            @group_id = TRY_CAST(group_id AS INT),
            @group_start = TRY_CAST(start_date AS DATE),
            @weekdays_mask = TRY_CAST(weekdays AS BIGINT)
        FROM master.dbo.[Group]
        WHERE group_name = @group_name;
    END

    -- Вернуть NULL если группа не найдена
    IF @group_id IS NULL
        RETURN NULL;

    -- Получить последнюю дату по расписанию
    IF OBJECT_ID('dbo.GetLastDate', 'FN') IS NOT NULL
    BEGIN
        BEGIN TRY
            SET @last_date = dbo.GetLastDate(@group_name);
        END TRY
        BEGIN CATCH
            SET @last_date = NULL;
        END CATCH
    END
    ELSE
    BEGIN
        -- Фоллбек: считать из Schedule если есть
        IF OBJECT_ID('master.dbo.Schedule', 'U') IS NOT NULL
        BEGIN
            SELECT @last_date = MAX([date]) FROM master.dbo.Schedule WHERE [group] = @group_id;
        END
    END

    -- Начало поиска: после последней даты или start_date или сегодня
    SET @search_start = COALESCE(@last_date, @group_start, CAST(GETDATE() AS DATE));
    SET @candidate = DATEADD(DAY, 1, @search_start);
    SET @limit = DATEADD(DAY, 365, @search_start); -- Предел поиска

    -- Маска по умолчанию Пн..Пт
    IF @weekdays_mask IS NULL
        SET @weekdays_mask = 31; -- 00011111

    -- Проверка наличия таблицы праздников и её колонок
    DECLARE @hol_exists BIT = 0;
    DECLARE @hol_has_holiday_date BIT = 0;
    DECLARE @hol_has_start_end BIT = 0;
    DECLARE @hol_has_recurring_mmdd BIT = 0;
    DECLARE @hol_qualified NVARCHAR(128) = N'master.dbo.Holidays';

    IF OBJECT_ID(@hol_qualified, 'U') IS NOT NULL
        SET @hol_exists = 1;

    IF @hol_exists = 1
    BEGIN
        IF EXISTS (SELECT 1 FROM master.sys.columns WHERE object_id = OBJECT_ID(@hol_qualified) AND LOWER(name) = 'holiday_date')
            SET @hol_has_holiday_date = 1;
        IF EXISTS (SELECT 1 FROM master.sys.columns WHERE object_id = OBJECT_ID(@hol_qualified) AND LOWER(name) = 'start_date')
           AND EXISTS (SELECT 1 FROM master.sys.columns WHERE object_id = OBJECT_ID(@hol_qualified) AND LOWER(name) = 'end_date')
            SET @hol_has_start_end = 1;
        IF EXISTS (SELECT 1 FROM master.sys.columns WHERE object_id = OBJECT_ID(@hol_qualified) AND LOWER(name) = 'recurring_start_month')
           AND EXISTS (SELECT 1 FROM master.sys.columns WHERE object_id = OBJECT_ID(@hol_qualified) AND LOWER(name) = 'recurring_start_day')
           AND EXISTS (SELECT 1 FROM master.sys.columns WHERE object_id = OBJECT_ID(@hol_qualified) AND LOWER(name) = 'recurring_end_month')
           AND EXISTS (SELECT 1 FROM master.sys.columns WHERE object_id = OBJECT_ID(@hol_qualified) AND LOWER(name) = 'recurring_end_day')
            SET @hol_has_recurring_mmdd = 1;
    END

    -- Основной цикл поиска подходящей даты
    WHILE @candidate <= @limit
    BEGIN
        DECLARE @is_holiday BIT = 0;

        -- Проверка праздников
        IF @hol_exists = 1
        BEGIN
            -- Точная дата
            IF @hol_has_holiday_date = 1
            BEGIN
                IF EXISTS (SELECT 1 FROM master.dbo.Holidays h WHERE h.holiday_date = @candidate)
                    SET @is_holiday = 1;
            END

            -- Абсолютный диапазон
            IF @is_holiday = 0 AND @hol_has_start_end = 1
            BEGIN
                IF EXISTS (SELECT 1 FROM master.dbo.Holidays h WHERE h.start_date IS NOT NULL AND h.end_date IS NOT NULL AND @candidate BETWEEN h.start_date AND h.end_date)
                    SET @is_holiday = 1;
            END

            -- Recurring через явные mm/dd
            IF @is_holiday = 0 AND @hol_has_recurring_mmdd = 1
            BEGIN
                DECLARE @mmdd INT = MONTH(@candidate) * 100 + DAY(@candidate);
                IF EXISTS (
                    SELECT 1 FROM master.dbo.Holidays h
                    WHERE ISNULL(h.recurring, 0) = 1
                      AND h.recurring_start_month IS NOT NULL
                      AND h.recurring_start_day IS NOT NULL
                      AND h.recurring_end_month IS NOT NULL
                      AND h.recurring_end_day IS NOT NULL
                      AND (
                        (
                          (h.recurring_start_month * 100 + h.recurring_start_day)
                          <= (h.recurring_end_month * 100 + h.recurring_end_day)
                          AND @mmdd BETWEEN (h.recurring_start_month * 100 + h.recurring_start_day)
                                       AND (h.recurring_end_month * 100 + h.recurring_end_day)
                        )
                        OR
                        (
                          (h.recurring_start_month * 100 + h.recurring_start_day)
                          > (h.recurring_end_month * 100 + h.recurring_end_day)
                          AND (@mmdd >= (h.recurring_start_month * 100 + h.recurring_start_day) OR @mmdd <= (h.recurring_end_month * 100 + h.recurring_end_day))
                        )
                      )
                )
                    SET @is_holiday = 1;
            END

            -- Recurring через month/day из start_date/end_date если явных полей нет
            IF @is_holiday = 0 AND @hol_has_start_end = 1 AND @hol_has_recurring_mmdd = 0
            BEGIN
                DECLARE @mmdd2 INT = MONTH(@candidate) * 100 + DAY(@candidate);
                IF EXISTS (
                    SELECT 1 FROM master.dbo.Holidays h
                    WHERE ISNULL(h.recurring, 0) = 1
                      AND h.start_date IS NOT NULL AND h.end_date IS NOT NULL
                      AND (
                        (
                          (MONTH(h.start_date) * 100 + DAY(h.start_date))
                          <= (MONTH(h.end_date) * 100 + DAY(h.end_date))
                          AND @mmdd2 BETWEEN (MONTH(h.start_date) * 100 + DAY(h.start_date))
                                        AND (MONTH(h.end_date) * 100 + DAY(h.end_date))
                        )
                        OR
                        (
                          (MONTH(h.start_date) * 100 + DAY(h.start_date))
                          > (MONTH(h.end_date) * 100 + DAY(h.end_date))
                          AND (@mmdd2 >= (MONTH(h.start_date) * 100 + DAY(h.start_date)) OR @mmdd2 <= (MONTH(h.end_date) * 100 + DAY(h.end_date)))
                        )
                      )
                )
                    SET @is_holiday = 1;
            END
        END

        IF @is_holiday = 1
        BEGIN
            SET @candidate = DATEADD(DAY, 1, @candidate);
            CONTINUE;
        END

        -- Вычислить ISO-подобный день недели (Пн=1..Вс=7)
        DECLARE @iso_wd TINYINT = ((DATEPART(WEEKDAY, @candidate) + @@DATEFIRST - 2) % 7) + 1;
        DECLARE @maskbit BIGINT = CAST(POWER(CONVERT(FLOAT, 2), @iso_wd - 1) AS BIGINT);

        -- Проверка по маске рабочих дней
        IF (@weekdays_mask & @maskbit) <> 0
        BEGIN
            SET @result = @candidate;
            BREAK;
        END

        SET @candidate = DATEADD(DAY, 1, @candidate);
    END

    RETURN @result;
END
GO

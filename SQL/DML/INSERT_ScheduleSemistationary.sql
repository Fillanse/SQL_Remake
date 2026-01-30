USE master;
GO

CREATE OR ALTER PROCEDURE dbo.INSERT_ScheduleSemistationary
    @group_id INT,
    @discipline_id SMALLINT,
    @teacher_id INT,
    @start_date DATE,
    @end_date DATE,
    @weekday TINYINT,
    @time TIME,
    @subject NVARCHAR(256) = NULL,
    @frequency_weeks TINYINT = 1,
    @max_rows INT = 1000
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @start_date IS NULL OR @end_date IS NULL OR @start_date > @end_date
    BEGIN
        PRINT 'Invalid date range.';
        RETURN -1;
    END
    IF @weekday < 1 OR @weekday > 7
    BEGIN
        PRINT 'Invalid weekday (1..7 expected).';
        RETURN -1;
    END

    IF NOT EXISTS(SELECT 1 FROM master.dbo.[Group] WHERE group_id = @group_id)
    BEGIN
        PRINT FORMATMESSAGE('Group with id %d not found.', @group_id);
        RETURN -1;
    END
    IF NOT EXISTS(SELECT 1 FROM master.dbo.Disciplines WHERE discipline_id = @discipline_id)
    BEGIN
        PRINT FORMATMESSAGE('Discipline with id %d not found.', @discipline_id);
        RETURN -1;
    END
    IF NOT EXISTS(SELECT 1 FROM master.dbo.Teachers WHERE teacher_id = @teacher_id)
    BEGIN
        PRINT FORMATMESSAGE('Teacher with id %d not found.', @teacher_id);
        RETURN -1;
    END

    DECLARE @first DATE = @start_date;
    DECLARE @offset INT = (@weekday - DATEPART(WEEKDAY, @first) + 7) % 7;
    SET @first = DATEADD(DAY, @offset, @first);

    IF @first > @end_date
    BEGIN
        PRINT 'No matching dates in range.';
        RETURN 0;
    END

    DECLARE @days INT = DATEDIFF(DAY, @first, @end_date);
    DECLARE @occurrences INT = (@days / (7 * @frequency_weeks)) + 1;
    IF @occurrences <= 0
    BEGIN
        PRINT 'No occurrences calculated.';
        RETURN 0;
    END

    IF @occurrences > @max_rows
    BEGIN
        PRINT FORMATMESSAGE('Operation would insert %d rows which exceeds @max_rows (%d).', @occurrences, @max_rows);
        RETURN -1;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewDates TABLE (LessonDate DATE PRIMARY KEY);

        ;WITH
        Tally(n) AS
        (
            SELECT TOP (@occurrences) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1
            FROM master.sys.all_objects a CROSS JOIN master.sys.all_objects b
        ),
        Dates AS
        (
            SELECT DATEADD(DAY, n * (7 * @frequency_weeks), @first) AS LessonDate
            FROM Tally
        )
        INSERT INTO @NewDates(LessonDate)
        SELECT d.LessonDate
        FROM Dates d
        LEFT JOIN master.dbo.Schedule s
            ON s.[group] = @group_id
            AND s.[date] = d.LessonDate
            AND s.[time] = @time
            AND s.discipline = @discipline_id
        WHERE s.lesson_id IS NULL;

        SELECT @occurrences = COUNT(*) FROM @NewDates;

        IF @occurrences = 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'No new schedule rows to insert (already present).';
            RETURN 0;
        END

        INSERT INTO master.dbo.Schedule ([date], [time], [group], discipline, teacher, spent, [subject])
        SELECT LessonDate, @time, @group_id, @discipline_id, @teacher_id, 0, @subject
        FROM @NewDates;

        DECLARE @Inserted INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        PRINT FORMATMESSAGE('Inserted %d rows into Schedule.', @Inserted);
        SELECT @Inserted AS InsertedRows;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT FORMATMESSAGE('Error in INSERT ScheduleSemistationary: %s', @ErrMsg);
        RETURN -1;
    END CATCH
END
GO
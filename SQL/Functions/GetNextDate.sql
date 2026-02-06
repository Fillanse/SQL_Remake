USE master
GO

CREATE FUNCTION dbo.GetNextDate
(
    @GroupId INT
)
RETURNS DATE
AS
BEGIN
    DECLARE
        @LastDate DATE,
        @NextDate DATE,
        @Weekdays TINYINT,
        @DayMask TINYINT;

    SELECT @LastDate = MAX([date])
    FROM Schedule
    WHERE [group] = @GroupId;

    IF @LastDate IS NULL
        SELECT @LastDate = start_date
        FROM [Group]
        WHERE group_id = @GroupId;

    SELECT @Weekdays = weekdays
    FROM [Group]
    WHERE group_id = @GroupId;

    SET @NextDate = DATEADD(DAY, 1, @LastDate);

    WHILE 1 = 1
    BEGIN
        SET @DayMask =
            CASE DATEPART(WEEKDAY, @NextDate)
                WHEN 1 THEN 64  -- Su
                WHEN 2 THEN 1   -- Mo
                WHEN 3 THEN 2   -- Te
                WHEN 4 THEN 4   -- We
                WHEN 5 THEN 8   -- Th
                WHEN 6 THEN 16  -- Fr
                WHEN 7 THEN 32  -- Sa
            END;

        IF (@Weekdays & @DayMask) <> 0
           AND NOT EXISTS (
                SELECT 1
                FROM NonStudyDays
                WHERE @NextDate BETWEEN date_from AND date_to
           )
        BEGIN
            RETURN @NextDate;
        END;

        SET @NextDate = DATEADD(DAY, 1, @NextDate);
    END;

    RETURN NULL;
END;
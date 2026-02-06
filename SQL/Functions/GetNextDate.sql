USE master
GO

CREATE FUNCTION dbo.GetNextDate(@group_name AS NVARCHAR(24))
RETURNS TINYINT
AS
    BEGIN
        DECLARE @group_id AS INT = (SELECT group_id FROM [Group] WHERE group_name=@group_name);
        DECLARE @learning_days AS TINYINT = (SELECT weekdays FROM [Group] WHERE group_id=@group_name);
        DECLARE @last_date AS DATE = dbo.GetLastDate(@group_name);
        DECLARE @weekday AS TINYINT = DATEPART(WEEKDAY, @last_date);
        DECLARE @day AS TINYINT = @weekday;
        DECLARE @next_day AS TINYINT = 0;
        WHILE @day < 7
        IF (POWER(2,@day) & @learning_days > 0)
        BEGIN
            SET @next_day = @day;
            BREAK;
        END
        IF @next_day = @weekday
        BEGIN
            SET @day = 1;
            WHILE @day < @weekday
            BEGIN
                IF POWER(2,@day-1) & @learning_days > 0
                BEGIN
                   SET @next_day=@day;
                   BREAK;
                END
                SET @next_day = @day+1;
            END
        END
    RETURN @next_day
    END
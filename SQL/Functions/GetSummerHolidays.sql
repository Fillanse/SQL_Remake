SET DATEFIRST 1;

CREATE FUNCTION GetSummerHolidays(@year AS SMALLINT) RETURNS DATE
AS
    BEGIN
        DECLARE @start_date AS DATE = DATEFROMPARTS(@year, 7, 31);
        DECLARE @weekday AS TINYINT = DATEPART(WEEKDAY, @start_date);
        SET @start_date = DATEADD(DAY, -@weekday+1, @start_date);
        IF @weekday = 1 SET @start_date = DATEADD(DAY, -7, @start_date);
        RETURN @start_date
    end
SET DATEFIRST 1;
GO
CREATE FUNCTION GetHolidayStartDate(@holiday NVARCHAR(150), @year SMALLINT) RETURNS DATE
AS
    BEGIN
        DECLARE @month AS TINYINT = (SELECT [month] FROM Holidays WHERE holiday_name LIKE @holiday)
        DECLARE @day AS TINYINT = (SELECT [day] FROM Holidays WHERE holiday_name LIKE @holiday)
        DECLARE @start_date AS DATE = (
            CASE
                WHEN @holiday LIKE N'Новый%' THEN dbo.GetNewYear(@year)
                WHEN @holiday LIKE N'Летние%' THEN dbo.SummerHolidays(@year)
                WHEN @holiday LIKE N'Пасха' THEN  dbo.GetEasterDate(@year)
                WHEN @month != 0 AND @day != 0 THEN  DATEFROMPARTS(@year,@month,@day)
            END
            );
        RETURN @start_date;
    end
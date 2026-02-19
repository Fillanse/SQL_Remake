USE SPU_411;
SET DATEFIRST 1;
GO
CREATE OR ALTER PROCEDURE INSERT_Holidays
    @year AS SMALLINT,
    @name AS NVARCHAR(150)
AS
    BEGIN
        DECLARE @start_date AS DATE = dbo.GetHolidaysStartDate(@name, @year),
        @duration AS TINYINT = (SELECT duration FROM Holidays WHERE holiday_name LIKE @name),
        @holiday_id AS TINYINT = (SELECT holiday_id FROM Holidays WHERE holiday_name LIKE @name);

        DECLARE
        @date AS DATE = @start_date,
        @day AS TINYINT = 0;
        WHILE @day < @duration
        BEGIN
            INSERT DaysOff([date], holiday)
            VALUES (@date, @holiday_id)
            SET @day += 1;
            SET @date = DATEADD(DAY, 1, @date);
        end
    end
SET DATEFIRST 1;
GO
CREATE OR ALTER PROCEDURE INSERT_AllHolidays @year AS SMALLINT
AS
BEGIN
    EXEC INSERT_Holidays @year, N'Новый%';
    EXEC INSERT_Holidays @year, N'Пасха';
    EXEC INSERT_Holidays @year, N'23%';
    EXEC INSERT_Holidays @year, N'Майские%';
    EXEC INSERT_Holidays @year, N'8%';
    EXEC INSERT_Holidays @year, N'Летние%';
end
CREATE FUNCTION GetEasterDate(@year AS SMALLINT) RETURNS DATE
AS
    BEGIN
        DECLARE @a AS SMALLINT = @year%19;
        DECLARE @b AS SMALLINT = @year%4;
        DECLARE @c AS SMALLINT = @year%7;
        DECLARE @d AS SMALLINT = (@a + 15) % 30;
        DECLARE @e AS SMALLINT = (2*@b + 4*@c + 6*@d + 6) % 7;
        DECLARE @f AS SMALLINT = @d + @e;
        DECLARE @easter_date AS DATE;
        IF @f <= 26 SET @easter_date = DATEFROMPARTS(@year, 4, 4 + @f);
        ELSE SET @easter_date = DATEFROMPARTS(@year, 5, @f - 26)
        RETURN @easter_date;
    end
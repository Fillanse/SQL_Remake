USE master
GO

CREATE FUNCTION GetLastDate(@group_name AS NVARCHAR(24))
RETURNS DATE
AS
    BEGIN
        DECLARE @group_id AS INT = (SELECT group_id FROM [Group] WHERE group_name=@group_name);
        DECLARE @last_date AS DATE = NULL;
        IF EXISTS(SELECT [group] FROM Schedule WHERE [group]=@group_id)
            SET @last_date = (SELECT MAX([date]) FROM Schedule WHERE [group]=@group_id);
        RETURN @last_date;
    END

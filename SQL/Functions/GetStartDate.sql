USE master
GO

CREATE FUNCTION GetStartDate(@group_name AS NVARCHAR(24))
RETURNS DATE
BEGIN
    DECLARE @group_id AS INT = (SELECT group_id FROM [Group] WHERE group_name = @group_name)
    DECLARE @start_date AS DATE = NULL;
    IF dbo.GetLastDate(@group_name) = NULL
        @start_date = (SELECT start_date FROM [Group] WHERE group_id = @group_id)
    ELSE
        @start_date = dbo.GetLastDate(@group_name + GetNextDate(@group_name))
END
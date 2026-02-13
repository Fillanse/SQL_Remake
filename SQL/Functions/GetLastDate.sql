USE master;
GO

CREATE OR ALTER FUNCTION dbo.GetLastDate(@group_name NVARCHAR(24))
RETURNS DATE
AS
BEGIN
    -- Получить id группы по имени
    DECLARE @group_id INT = (SELECT group_id FROM master.dbo.Groups WHERE group_name = @group_name);

    -- Если группа не найдена, вернуть NULL
    IF @group_id IS NULL
        RETURN NULL;

    -- Максимальная дата занятий для группы
    DECLARE @last_date DATE;
    SELECT @last_date = MAX([date]) FROM master.dbo.Schedule WHERE [group] = @group_id;

    RETURN @last_date;
END
GO

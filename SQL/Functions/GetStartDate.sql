USE master;
GO

-- Возвращает стартовую дату для группы.
-- Если расписание пустое -> вернуть Groups.start_date.
-- Иначе -> вернуть следующую дату после последней через dbo.GetNextDate.
CREATE OR ALTER FUNCTION dbo.GetStartDate(@group_name NVARCHAR(24))
RETURNS DATE
AS
BEGIN
    -- Попытка найти группу в master.dbo.Groups
    DECLARE @group_id INT = NULL;
    DECLARE @grp_start DATE = NULL;
    DECLARE @last DATE = NULL;

    IF OBJECT_ID('master.dbo.Groups','U') IS NOT NULL
    BEGIN
        SELECT TOP(1)
            @group_id = TRY_CAST(group_id AS INT),
            @grp_start = TRY_CAST(start_date AS DATE)
        FROM master.dbo.Groups
        WHERE group_name = @group_name;
    END

    -- Проверка legacy таблицы master.dbo.[Group]
    IF @group_id IS NULL AND OBJECT_ID('master.dbo.[Group]','U') IS NOT NULL
    BEGIN
        SELECT TOP(1)
            @group_id = TRY_CAST(group_id AS INT),
            @grp_start = TRY_CAST(start_date AS DATE)
        FROM master.dbo.[Group]
        WHERE group_name = @group_name;
    END

    -- Если группа не найдена -> NULL
    IF @group_id IS NULL
        RETURN NULL;

    -- Получить последнюю дату через helper, если есть
    IF OBJECT_ID('dbo.GetLastDate','FN') IS NOT NULL
    BEGIN
        BEGIN TRY
            SET @last = dbo.GetLastDate(@group_name);
        END TRY
        BEGIN CATCH
            SET @last = NULL;
        END CATCH
    END
    ELSE
    BEGIN
        -- Если helper отсутствует, взять напрямую из Schedule
        IF OBJECT_ID('master.dbo.Schedule','U') IS NOT NULL
        BEGIN
            SELECT @last = MAX([date]) FROM master.dbo.Schedule WHERE [group] = @group_id;
        END
    END

    -- Если записей нет -> вернуть старт группы
    IF @last IS NULL
    BEGIN
        RETURN @grp_start;
    END

    -- Если есть функция GetNextDate, вернуть её результат
    IF OBJECT_ID('dbo.GetNextDate','FN') IS NOT NULL
        RETURN dbo.GetNextDate(@group_name);

    -- Иначе вернуть день после последней записи
    RETURN DATEADD(DAY, 1, @last);
END
GO

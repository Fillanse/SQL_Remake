USE master;
GO

-- Добавить колонки для расписания, если таблица отсутствует — выйти
IF OBJECT_ID('master.dbo.Groups','U') IS NULL
BEGIN
    PRINT N'Таблица master.dbo.Groups не найдена. Изменения не применены.';
    RETURN;
END
GO

-- Добавить колонку weekdays (битовая маска рабочих дней)
IF COL_LENGTH('master.dbo.Groups', 'weekdays') IS NULL
BEGIN
    ALTER TABLE master.dbo.Groups ADD weekdays TINYINT NULL;
    PRINT N'Добавлена колонка weekdays';
END
ELSE
BEGIN
    PRINT N'Колонка weekdays уже существует';
END
GO

-- Добавить колонку start_date (дата начала)
IF COL_LENGTH('master.dbo.Groups', 'start_date') IS NULL
BEGIN
    ALTER TABLE master.dbo.Groups ADD start_date DATE NULL;
    PRINT N'Добавлена колонка start_date';
END
ELSE
BEGIN
    PRINT N'Колонка start_date уже существует';
END
GO

-- Проверка добавленных колонок
SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('master.dbo.Groups')
  AND c.name IN ('weekdays', 'start_date');
GO

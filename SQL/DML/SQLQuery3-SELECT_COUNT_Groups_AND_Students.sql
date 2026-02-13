USE master;
GO

-- Запрос подсчёта групп и студентов по направлениям.
-- Выдаёт: общее число групп, число пустых групп (без студентов), число заполненных групп (с студентами), общее число студентов.
SET NOCOUNT ON;

-- Собрать все группы из возможных таблиц Groups и [Group].
IF OBJECT_ID('tempdb..#AllGroups') IS NOT NULL DROP TABLE #AllGroups;
CREATE TABLE #AllGroups (
    group_id INT,
    group_name NVARCHAR(150),
    direction TINYINT
);

IF OBJECT_ID('master.dbo.Groups','U') IS NOT NULL
BEGIN
    INSERT INTO #AllGroups (group_id, group_name, direction)
    SELECT group_id, TRY_CAST(group_name AS NVARCHAR(150)), TRY_CAST(direction AS TINYINT)
    FROM master.dbo.Groups;
END

IF OBJECT_ID('master.dbo.[Group]','U') IS NOT NULL
BEGIN
    INSERT INTO #AllGroups (group_id, group_name, direction)
    SELECT group_id, TRY_CAST(group_name AS NVARCHAR(150)), TRY_CAST(direction AS TINYINT)
    FROM master.dbo.[Group];
END

-- Подсчёт студентов в группах.
-- Структура Students в репозитории использует колонку [group] для связи.
WITH StudentsPerGroup AS (
    SELECT [group] AS group_id, COUNT(*) AS student_count
    FROM master.dbo.Students
    GROUP BY [group]
)

-- Итоговый отчёт по направлениям.
SELECT
    d.direction_id        AS DirectionId,
    d.direction_name      AS DirectionName,
    COUNT(ag.group_id)    AS TotalGroups,
    SUM(CASE WHEN ISNULL(spg.student_count, 0) = 0 THEN 1 ELSE 0 END) AS GroupsEmpty,
    SUM(CASE WHEN ISNULL(spg.student_count, 0) > 0 THEN 1 ELSE 0 END)  AS GroupsFilled,
    ISNULL(SUM(spg.student_count), 0) AS TotalStudents
FROM master.dbo.Directions d
LEFT JOIN #AllGroups ag ON ag.direction = d.direction_id
LEFT JOIN StudentsPerGroup spg ON spg.group_id = ag.group_id
GROUP BY d.direction_id, d.direction_name
ORDER BY d.direction_name;

-- Дополнительно вывести группы, которые не привязаны к направлениям (если такие есть).
IF EXISTS (SELECT 1 FROM #AllGroups ag WHERE ag.direction IS NULL)
BEGIN
    PRINT '--- Groups without direction ---';
    SELECT
        NULL AS DirectionId,
        N'No Direction' AS DirectionName,
        COUNT(ag.group_id) AS TotalGroups,
        SUM(CASE WHEN ISNULL(spg.student_count,0) = 0 THEN 1 ELSE 0 END) AS GroupsEmpty,
        SUM(CASE WHEN ISNULL(spg.student_count,0) > 0 THEN 1 ELSE 0 END) AS GroupsFilled,
        ISNULL(SUM(spg.student_count),0) AS TotalStudents
    FROM #AllGroups ag
    LEFT JOIN StudentsPerGroup spg ON spg.group_id = ag.group_id
    WHERE ag.direction IS NULL;
END

DROP TABLE #AllGroups;
GO

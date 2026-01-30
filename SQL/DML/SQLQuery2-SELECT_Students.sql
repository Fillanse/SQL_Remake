USE master;

SELECT
    FORMATMESSAGE(N'%s %s %s', last_name, first_name, middle_name) AS FullName,
    birth_date AS BirthDate,
    CAST(DATEDIFF(DAY,birth_date,GETDATE())/365.25 AS INT) AS Age,
    group_name AS [Group],
    direction_name AS Direction
FROM master.dbo.Students s
JOIN master.dbo.[Group] g ON s.[group] = g.group_id
JOIN master.dbo.Directions d ON g.direction = d.direction_id
WHERE d.direction_name LIKE N'%%'
ORDER BY last_name;

SELECT
    FORMATMESSAGE(N'%s %s %s', last_name, first_name, middle_name) AS FullName,
    birth_date AS BirthDate,
    CAST(DATEDIFF(DAY, birth_date, GETDATE())/365.25 AS INT) AS Age
FROM master.dbo.Teachers;

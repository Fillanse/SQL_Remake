USE master;

DECLARE @GroupId INT = NULL;

SELECT
    s.lesson_id,
    s.[date],
    DATENAME(WEEKDAY, s.[date]) AS WeekdayName,
    DATEPART(WEEKDAY, s.[date]) AS WeekdayNumber,
    s.[time],
    g.group_name,
    d.discipline,
    t.last_name + ' ' + t.first_name AS TeacherName,
    s.[subject],
    s.spent
FROM master.dbo.Schedule s
JOIN master.dbo.[Group] g ON s.[group] = g.group_id
JOIN master.dbo.Disciplines d ON s.discipline = d.discipline_id
JOIN master.dbo.Teachers t ON s.teacher = t.teacher_id
WHERE (@GroupId IS NULL OR s.[group] = @GroupId)
ORDER BY s.[date], s.[time];

USE master;
GO

DECLARE @GroupName NVARCHAR(50) = N'PV_319';
DECLARE @GroupId INT = (SELECT group_id FROM master.dbo.[Group] WHERE group_name = @GroupName);
IF @GroupId IS NULL
BEGIN
    PRINT FORMATMESSAGE(N'Group %s not found - nothing to do.', @GroupName);
    RETURN;
END

DECLARE @disciplines TABLE (name NVARCHAR(256));
INSERT INTO @disciplines(name) VALUES
(N'UML and Design Patterns'),
(N'Programming Language C#'),
(N'Windows Application Development in C++'),
(N'Windows Application Development in C#'),
(N'Database Theory and MS SQL Server Programming'),
(N'Data Access Technology ADO.NET'),
(N'Systems Programming'),
(N'Network Programming');

DECLARE @time TIME = '18:30';
DECLARE @StartDate DATE = '2026-01-01';
DECLARE @EndDate   DATE = '2026-06-30';

DECLARE @controlDate DATE = '2026-01-13';
DECLARE @obsTue INT = DATEPART(WEEKDAY, @controlDate);
DECLARE @expectedTue INT = 3;
DECLARE @shift INT = @expectedTue - @obsTue;
IF @shift <> 0
BEGIN
    PRINT FORMATMESSAGE(N'Warning: server DATEFIRST differs from expected; applying shift %d to weekday numbers.', @shift);
END

DECLARE @baseTue TINYINT = 3; DECLARE @baseThu TINYINT = 5; DECLARE @baseSat TINYINT = 7;
DECLARE @wdTue TINYINT = ((@baseTue + @shift - 1 + 7) % 7) + 1;
DECLARE @wdThu TINYINT = ((@baseThu + @shift - 1 + 7) % 7) + 1;
DECLARE @wdSat TINYINT = ((@baseSat + @shift - 1 + 7) % 7) + 1;

DECLARE @teacher_id INT;

DECLARE cur_disc CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM @disciplines;
DECLARE @dname NVARCHAR(256);
OPEN cur_disc;
FETCH NEXT FROM cur_disc INTO @dname;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @teacher_id = (SELECT TOP 1 teacher_id FROM master.dbo.Teachers t JOIN master.dbo.TeachersDisciplinesRelation r ON t.teacher_id = r.teacher WHERE r.discipline = (SELECT discipline_id FROM master.dbo.Disciplines WHERE discipline = @dname));
    IF @teacher_id IS NULL
        SET @teacher_id = (SELECT TOP 1 teacher_id FROM master.dbo.Teachers);

    DECLARE @discipline_id SMALLINT = (SELECT discipline_id FROM master.dbo.Disciplines WHERE discipline = @dname);
    IF @discipline_id IS NULL
    BEGIN
        PRINT FORMATMESSAGE(N'Discipline not found: %s - skipping.', @dname);
    END
    ELSE
    BEGIN
        DECLARE @weekdaylist TABLE (wd TINYINT);
        INSERT INTO @weekdaylist (wd) VALUES (@wdTue),(@wdThu),(@wdSat);

        DECLARE cur_wd CURSOR LOCAL FAST_FORWARD FOR SELECT wd FROM @weekdaylist;
        DECLARE @wd TINYINT;
        OPEN cur_wd;
        FETCH NEXT FROM cur_wd INTO @wd;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @firstLocal DATE = @StartDate;
            DECLARE @offsetLocal INT = (@wd - DATEPART(WEEKDAY, @firstLocal) + 7) % 7;
            SET @firstLocal = DATEADD(DAY, @offsetLocal, @firstLocal);

            DECLARE @expected INT = 0;
            IF @firstLocal <= @EndDate
            BEGIN
                DECLARE @daysLocal INT = DATEDIFF(DAY, @firstLocal, @EndDate);
                SET @expected = (@daysLocal / (7 * 1)) + 1;
            END

            DECLARE @existing INT = (
                SELECT COUNT(*) FROM master.dbo.Schedule s
                WHERE s.[group] = @GroupId
                  AND s.discipline = @discipline_id
                  AND s.[time] = @time
                  AND s.[date] BETWEEN @StartDate AND @EndDate
                  AND DATEPART(WEEKDAY, s.[date]) = @wd
            );

            IF @expected = 0
            BEGIN
                PRINT FORMATMESSAGE(N'No occurrences expected for %s on weekday %d in %s..%s', @dname, @wd, CONVERT(NVARCHAR(10),@StartDate,120), CONVERT(NVARCHAR(10),@EndDate,120));
            END
            ELSE IF @existing >= @expected
            BEGIN
                PRINT FORMATMESSAGE(N'Already complete for %s weekday %d - expected %d, existing %d. Skipping.', @dname, @wd, @expected, @existing);
            END
            ELSE
            BEGIN
                PRINT FORMATMESSAGE(N'Inserting missing rows for %s weekday %d - expected %d, existing %d.', @dname, @wd, @expected, @existing);
                EXEC dbo.sp_InsertScheduleSemistacionar @GroupId, @discipline_id, @teacher_id, @StartDate, @EndDate, @wd, @time, @dname, 1, 500;
            END

            FETCH NEXT FROM cur_wd INTO @wd;
        END
        CLOSE cur_wd;
        DEALLOCATE cur_wd;
    END

    FETCH NEXT FROM cur_disc INTO @dname;
END
CLOSE cur_disc;
DEALLOCATE cur_disc;

PRINT N'Finished populating PV_319 schedule.';
GO

USE SPU_411
GO

CREATE OR ALTER PROCEDURE INSERT_Schedule
    @group_name as nvarchar(24),
    @discipline_name as nvarchar(150),
    @teacher as nvarchar(50)
AS
    BEGIN
        DECLARE @group_id			AS	INT		=	(SELECT group_id		FROM Groups		 WHERE group_name=@group_name);
        DECLARE @discipline_id		AS	SMALLINT=	(SELECT discipline_id	FROM Disciplines WHERE discipline_name LIKE @discipline_name);
        DECLARE @number_of_lessons	AS	TINYINT =	(SELECT number_of_lessons FROM Disciplines WHERE discipline_id=@discipline_id);
        DECLARE @lesson_number		AS	TINYINT	=	(SELECT COUNT(discipline) FROM Schedule WHERE [group]=@group_id AND discipline=@discipline_id);
        DECLARE @teacher_id			AS	SMALLINT=	(SELECT teacher_id		FROM Teachers	 WHERE last_name = @teacher);
        DECLARE @date				AS	DATE	=	dbo.GetLastDate(@group_name);
        DECLARE @start_time			AS	TIME	=	(SELECT start_time		FROM Groups		 WHERE group_id=@group_id);
        DECLARE @time				AS	TIME	=	@start_time;

        IF @date IS NULL 
            SET @date = (SELECT start_date FROM Groups WHERE group_id=@group_id);

        IF @lesson_number > 0
        BEGIN
            PRINT 'Дисциплина ' + @discipline_name + ' уже есть в расписании для группы ' + @group_name;
            RETURN;
        END

        PRINT '--------------------------------------------------------------------';
        PRINT @group_id;
        PRINT @discipline_id;
        PRINT @teacher;
        PRINT @date;
        PRINT @time;
        PRINT @lesson_number;
        PRINT @number_of_lessons;
        PRINT '--------------------------------------------------------------------';

        WHILE @lesson_number < @number_of_lessons
        BEGIN
            IF dbo.GetLastDate(@group_name) IS NOT NULL 
                SET @date = dbo.GetNextDate(@group_id);
            
            SET @time = @start_time;
            
            WHILE @lesson_number < @number_of_lessons
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM Schedule 
                    WHERE [group] = @group_id 
                      AND discipline = @discipline_id 
                      AND [date] = @date 
                      AND [time] = @time
                )
                BEGIN
                    INSERT INTO Schedule ([group], discipline, teacher, [date], [time], spent)
                    VALUES (@group_id, @discipline_id, @teacher_id, @date, @time, 0);
                    SET @lesson_number = @lesson_number + 1;
                END
                
                IF @lesson_number >= @number_of_lessons BREAK;
                
                SET @time = DATEADD(MINUTE, 95, @time);
                
                IF @time <= (SELECT end_time FROM Groups WHERE group_id=@group_id)
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM Schedule 
                        WHERE [group] = @group_id 
                          AND discipline = @discipline_id 
                          AND [date] = @date 
                          AND [time] = @time
                    )
                    BEGIN
                        INSERT INTO Schedule ([group], discipline, teacher, [date], [time], spent)
                        VALUES (@group_id, @discipline_id, @teacher_id, @date, @time, 0);
                        SET @lesson_number = @lesson_number + 1;
                    END
                END
                
                IF @lesson_number >= @number_of_lessons BREAK;
            END
            
            SET @date = dbo.GetNextDate(@group_id);
            
            IF @date IS NULL BREAK;
        END
    END
GO

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'Schedule' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.Schedule (
        lesson_id BIGINT PRIMARY KEY,
        [date] DATE NOT NULL,
        [time] TIME NOT NULL,
        [group] INT NOT NULL,
        discipline SMALLINT NOT NULL,
        teacher INT NOT NULL,
        spent BIT NOT NULL,
        [subject] NVARCHAR(256) NULL
    );');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'AttendanceAndGrades' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.AttendanceAndGrades (
        student INT,
        lesson BIGINT,
        present BIT NOT NULL,
        grade_1 TINYINT NULL,
        grade_2 TINYINT NULL,
        PRIMARY KEY(student, lesson)
    );');
    EXEC('ALTER TABLE master.dbo.AttendanceAndGrades ADD CONSTRAINT CK_Grade_1 CHECK (grade_1 > 0 AND grade_1 <= 12);');
    EXEC('ALTER TABLE master.dbo.AttendanceAndGrades ADD CONSTRAINT CK_Grade_2 CHECK (grade_2 > 0 AND grade_2 <= 12);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'Exams' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.Exams (
        student INT,
        discipline SMALLINT,
        grade TINYINT,
        PRIMARY KEY(student, discipline)
    );');
    EXEC('ALTER TABLE master.dbo.Exams ADD CONSTRAINT CK_Grade CHECK (grade > 0 AND grade <= 12);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_Grades_Students')
BEGIN
    EXEC('ALTER TABLE master.dbo.AttendanceAndGrades ADD CONSTRAINT FK_Grades_Students FOREIGN KEY(student) REFERENCES master.dbo.Students(student_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_Grades_Schedule')
BEGIN
    EXEC('ALTER TABLE master.dbo.AttendanceAndGrades ADD CONSTRAINT FK_Grades_Schedule FOREIGN KEY(lesson) REFERENCES master.dbo.Schedule(lesson_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_Exams_Students')
BEGIN
    EXEC('ALTER TABLE master.dbo.Exams ADD CONSTRAINT FK_Exams_Students FOREIGN KEY(student) REFERENCES master.dbo.Students(student_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_Exams_Disciplines')
BEGIN
    EXEC('ALTER TABLE master.dbo.Exams ADD CONSTRAINT FK_Exams_Disciplines FOREIGN KEY(discipline) REFERENCES master.dbo.Disciplines(discipline_id);');
END
GO

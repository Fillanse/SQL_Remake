USE master;
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'Directions' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.Directions (direction_id TINYINT PRIMARY KEY, direction_name NVARCHAR(150) NOT NULL);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'Groups' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.Groups (group_id INT PRIMARY KEY, group_name NVARCHAR(24) NOT NULL, direction TINYINT NOT NULL);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'Students' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.Students (
        student_id INT PRIMARY KEY,
        last_name NVARCHAR(50) NOT NULL,
        first_name NVARCHAR(50) NOT NULL,
        middle_name NVARCHAR(50) NULL,
        birth_date DATE NOT NULL,
        [group] INT NOT NULL
    );');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_Students_Group')
BEGIN
    EXEC('ALTER TABLE master.dbo.Students ADD CONSTRAINT FK_Students_Group FOREIGN KEY([group]) REFERENCES master.dbo.Groups(group_id);');
END
GO

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'Teachers' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.Teachers (
        teacher_id INT PRIMARY KEY,
        last_name NVARCHAR(50) NOT NULL,
        first_name NVARCHAR(50) NOT NULL,
        middle_name NVARCHAR(50),
        birth_date DATE NOT NULL,
        rate MONEY NOT NULL
    );');
END
GO

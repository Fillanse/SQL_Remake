USE master;
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'Disciplines' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.Disciplines (
        discipline_id SMALLINT PRIMARY KEY,
        discipline_name NVARCHAR(256) NOT NULL,
        number_of_lessons TINYINT NOT NULL
    );');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'TeachersDisciplinesRelation' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.TeachersDisciplinesRelation (
        teacher INT,
        discipline SMALLINT,
        PRIMARY KEY(teacher, discipline)
    );');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'DisciplinesDirectionsRelation' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.DisciplinesDirectionsRelation (
        discipline SMALLINT,
        direction TINYINT,
        PRIMARY KEY(discipline, direction)
    );');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'RequiredDisciplines' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.RequiredDisciplines (
        discipline SMALLINT,
        required_discipline SMALLINT,
        PRIMARY KEY(discipline, required_discipline)
    );');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.tables WHERE name = 'DependentDisciplines' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    EXEC('CREATE TABLE master.dbo.DependentDisciplines (
        discipline SMALLINT,
        dependent_discipline SMALLINT,
        PRIMARY KEY(discipline, dependent_discipline)
    );');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_TDR_Teacher')
BEGIN
    EXEC('ALTER TABLE master.dbo.TeachersDisciplinesRelation ADD CONSTRAINT FK_TDR_Teacher FOREIGN KEY(teacher) REFERENCES master.dbo.Teachers(teacher_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_TDR_Discipline')
BEGIN
    EXEC('ALTER TABLE master.dbo.TeachersDisciplinesRelation ADD CONSTRAINT FK_TDR_Discipline FOREIGN KEY(discipline) REFERENCES master.dbo.Disciplines(discipline_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_DDR_Discipline')
BEGIN
    EXEC('ALTER TABLE master.dbo.DisciplinesDirectionsRelation ADD CONSTRAINT FK_DDR_Discipline FOREIGN KEY(discipline) REFERENCES master.dbo.Disciplines(discipline_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_DDR_Direction')
BEGIN
    EXEC('ALTER TABLE master.dbo.DisciplinesDirectionsRelation ADD CONSTRAINT FK_DDR_Direction FOREIGN KEY(direction) REFERENCES master.dbo.Directions(direction_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_RD_Discipline')
BEGIN
    EXEC('ALTER TABLE master.dbo.RequiredDisciplines ADD CONSTRAINT FK_RD_Discipline FOREIGN KEY(discipline) REFERENCES master.dbo.Disciplines(discipline_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_RD_Requires')
BEGIN
    EXEC('ALTER TABLE master.dbo.RequiredDisciplines ADD CONSTRAINT FK_RD_Requires FOREIGN KEY(required_discipline) REFERENCES master.dbo.Disciplines(discipline_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_DD_Discipline')
BEGIN
    EXEC('ALTER TABLE master.dbo.DependentDisciplines ADD CONSTRAINT FK_DD_Discipline FOREIGN KEY(discipline) REFERENCES master.dbo.Disciplines(discipline_id);');
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.foreign_keys WHERE name = 'FK_DD_Dependent')
BEGIN
    EXEC('ALTER TABLE master.dbo.DependentDisciplines ADD CONSTRAINT FK_DD_Dependent FOREIGN KEY(dependent_discipline) REFERENCES master.dbo.Disciplines(discipline_id);');
END
GO

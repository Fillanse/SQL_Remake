USE master;
GO

IF OBJECT_ID('master.dbo.Schedule','U') IS NULL
BEGIN
    PRINT 'Table master.dbo.Schedule not found — skipping ALTER/INDEX creation.';
    RETURN;
END

IF master.sys.columns.COLUMNPROPERTY(OBJECT_ID('master.dbo.Schedule'), 'WeekdayNumber', 'ColumnId') IS NULL
BEGIN
    EXEC('ALTER TABLE master.dbo.Schedule ADD WeekdayNumber AS DATEPART(WEEKDAY, [date]) PERSISTED;');
    PRINT 'Added column WeekdayNumber.';
END
ELSE
BEGIN
    PRINT 'Column WeekdayNumber already exists.';
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.indexes WHERE name = 'IX_Schedule_Group_Date_Time' AND object_id = OBJECT_ID('master.dbo.Schedule'))
BEGIN
    EXEC('CREATE NONCLUSTERED INDEX IX_Schedule_Group_Date_Time ON master.dbo.Schedule([group],[date],[time]) INCLUDE (discipline, teacher, [subject], WeekdayNumber);');
    PRINT 'Created index IX_Schedule_Group_Date_Time.';
END
ELSE
BEGIN
    PRINT 'Index IX_Schedule_Group_Date_Time already exists.';
END
GO

IF NOT EXISTS (SELECT 1 FROM master.sys.indexes WHERE name = 'IX_Schedule_Weekday' AND object_id = OBJECT_ID('master.dbo.Schedule'))
BEGIN
    EXEC('CREATE NONCLUSTERED INDEX IX_Schedule_Weekday ON master.dbo.Schedule(WeekdayNumber, [date]);');
    PRINT 'Created index IX_Schedule_Weekday.';
END
ELSE
BEGIN
    PRINT 'Index IX_Schedule_Weekday already exists.';
END
GO

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM master.dbo.Directions WHERE direction_id = 1)
    INSERT INTO master.dbo.Directions(direction_id, direction_name) VALUES (1, N'Software Engineering and Applied Technologies');
IF NOT EXISTS (SELECT 1 FROM master.dbo.Directions WHERE direction_id = 2)
    INSERT INTO master.dbo.Directions(direction_id, direction_name) VALUES (2, N'Information Systems and Technologies');
IF NOT EXISTS (SELECT 1 FROM master.dbo.Directions WHERE direction_id = 3)
    INSERT INTO master.dbo.Directions(direction_id, direction_name) VALUES (3, N'Network Technologies and Security');

SELECT * FROM master.dbo.Directions;

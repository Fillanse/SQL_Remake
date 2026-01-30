USE master;
GO

IF NOT EXISTS (SELECT 1 FROM master.dbo.[Group] WHERE group_id = 1)
    INSERT INTO master.dbo.[Group] (group_id, group_name, direction) VALUES (1, N'PU_211', 1);
IF NOT EXISTS (SELECT 1 FROM master.dbo.[Group] WHERE group_id = 2)
    INSERT INTO master.dbo.[Group] (group_id, group_name, direction) VALUES (2, N'PV_211', 1);
IF NOT EXISTS (SELECT 1 FROM master.dbo.[Group] WHERE group_id = 3)
    INSERT INTO master.dbo.[Group] (group_id, group_name, direction) VALUES (3, N'PD_212', 1);
IF NOT EXISTS (SELECT 1 FROM master.dbo.[Group] WHERE group_id = 4)
    INSERT INTO master.dbo.[Group] (group_id, group_name, direction) VALUES (4, N'PD_321', 1);
IF NOT EXISTS (SELECT 1 FROM master.dbo.[Group] WHERE group_id = 5)
    INSERT INTO master.dbo.[Group] (group_id, group_name, direction) VALUES (5, N'PV_319', 1);
IF NOT EXISTS (SELECT 1 FROM master.dbo.[Group] WHERE group_id = 6)
    INSERT INTO master.dbo.[Group] (group_id, group_name, direction) VALUES (6, N'SU_211', 2);
IF NOT EXISTS (SELECT 1 FROM master.dbo.[Group] WHERE group_id = 7)
    INSERT INTO master.dbo.[Group] (group_id, group_name, direction) VALUES (7, N'SV_211', 2);
IF NOT EXISTS (SELECT 1 FROM master.dbo.[Group] WHERE group_id = 8)
    INSERT INTO master.dbo.[Group] (group_id, group_name, direction) VALUES (8, N'DU_314', 3);

SELECT
    g.group_id AS ID,
    g.group_name AS GroupName,
    d.direction_name AS Direction
FROM master.dbo.[Group] g
JOIN master.dbo.Directions d ON g.direction = d.direction_id;

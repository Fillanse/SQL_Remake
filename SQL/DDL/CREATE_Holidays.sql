USE master;
GO

-- Таблица праздников: одиночные даты, диапазоны, ежегодные повторы
IF NOT EXISTS (
    SELECT 1 FROM master.sys.tables
    WHERE name = 'Holidays' AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    EXEC('CREATE TABLE master.dbo.Holidays (
        holiday_id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(200) NOT NULL,
        holiday_date DATE NULL,
        start_date DATE NULL,
        end_date DATE NULL,
        recurring BIT NOT NULL DEFAULT(0),
        recurring_start_month TINYINT NULL,
        recurring_start_day TINYINT NULL,
        recurring_end_month TINYINT NULL,
        recurring_end_day TINYINT NULL,
        is_academic BIT NOT NULL DEFAULT(0),
        notes NVARCHAR(1000) NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );');
    PRINT 'Created master.dbo.Holidays table.';
END
GO

-- Индекс по точной дате
IF NOT EXISTS (SELECT 1 FROM master.sys.indexes WHERE name = 'IX_Holidays_HolidayDate' AND object_id = OBJECT_ID('master.dbo.Holidays'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Holidays_HolidayDate ON master.dbo.Holidays(holiday_date);
END
GO

-- Индекс по диапазонам
IF NOT EXISTS (SELECT 1 FROM master.sys.indexes WHERE name = 'IX_Holidays_StartEnd' AND object_id = OBJECT_ID('master.dbo.Holidays'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Holidays_StartEnd ON master.dbo.Holidays(start_date, end_date);
END
GO

-- Индекс для Recurring-проверок
IF NOT EXISTS (SELECT 1 FROM master.sys.indexes WHERE name = 'IX_Holidays_RecurringMask' AND object_id = OBJECT_ID('master.dbo.Holidays'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Holidays_RecurringMask ON master.dbo.Holidays(recurring, recurring_start_month, recurring_start_day, recurring_end_month, recurring_end_day);
END
GO

-- Функция: 1 если дата является праздником/каникулом, иначе 0
CREATE OR ALTER FUNCTION dbo.IsHoliday(@d DATE)
RETURNS BIT
AS
BEGIN
    IF @d IS NULL RETURN 0;

    -- Точная дата
    IF EXISTS (
        SELECT 1 FROM master.dbo.Holidays h
        WHERE h.holiday_date = @d
    )
        RETURN 1;

    -- Абсолютный диапазон start_date..end_date
    IF EXISTS (
        SELECT 1 FROM master.dbo.Holidays h
        WHERE h.start_date IS NOT NULL AND h.end_date IS NOT NULL AND @d BETWEEN h.start_date AND h.end_date
    )
        RETURN 1;

    -- Ежегодный повтор по явным полям recurring_start_month/day .. recurring_end_month/day
    DECLARE @mmdd INT = MONTH(@d) * 100 + DAY(@d);

    IF EXISTS (
        SELECT 1 FROM master.dbo.Holidays h
        WHERE ISNULL(h.recurring, 0) = 1
          AND h.recurring_start_month IS NOT NULL
          AND h.recurring_start_day IS NOT NULL
          AND h.recurring_end_month IS NOT NULL
          AND h.recurring_end_day IS NOT NULL
          AND (
            (
              (h.recurring_start_month * 100 + h.recurring_start_day)
              <= (h.recurring_end_month * 100 + h.recurring_end_day)
              AND @mmdd BETWEEN (h.recurring_start_month * 100 + h.recurring_start_day)
                           AND (h.recurring_end_month * 100 + h.recurring_end_day)
            )
            OR
            (
              (h.recurring_start_month * 100 + h.recurring_start_day)
              > (h.recurring_end_month * 100 + h.recurring_end_day)
              AND (@mmdd >= (h.recurring_start_month * 100 + h.recurring_start_day) OR @mmdd <= (h.recurring_end_month * 100 + h.recurring_end_day))
            )
          )
    )
        RETURN 1;

    -- Ежегодный повтор по month/day частей start_date..end_date если явных полей нет
    IF EXISTS (
        SELECT 1 FROM master.dbo.Holidays h
        WHERE ISNULL(h.recurring, 0) = 1
          AND h.start_date IS NOT NULL AND h.end_date IS NOT NULL
          AND (
            (
              (MONTH(h.start_date) * 100 + DAY(h.start_date))
              <= (MONTH(h.end_date) * 100 + DAY(h.end_date))
              AND @mmdd BETWEEN (MONTH(h.start_date) * 100 + DAY(h.start_date))
                            AND (MONTH(h.end_date) * 100 + DAY(h.end_date))
            )
            OR
            (
              (MONTH(h.start_date) * 100 + DAY(h.start_date))
              > (MONTH(h.end_date) * 100 + DAY(h.end_date))
              AND (@mmdd >= (MONTH(h.start_date) * 100 + DAY(h.start_date)) OR @mmdd <= (MONTH(h.end_date) * 100 + DAY(h.end_date)))
            )
          )
    )
        RETURN 1;

    RETURN 0;
END
GO

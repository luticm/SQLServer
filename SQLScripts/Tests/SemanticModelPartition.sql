CREATE TABLE [dbo].[FactSales](
	[SalesOrderID] [int] IDENTITY(1,1) NOT NULL,	
	[OrderDate] [datetime2](0) NOT NULL,	
	[SalesOrderNumber] AS (isnull(N'SO'+CONVERT([nvarchar](23),[SalesOrderID]),N'*** ERROR ***')),
	[PurchaseOrderNumber] VARCHAR(20) NULL,
	[CustomerID] INT NOT NULL,	
	[Total] DECIMAL(10,2) NOT NULL,	
	[rowguid] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
)
GO

ALTER TABLE [dbo].[FactSales]
ADD CONSTRAINT [PK_SalesOrderHeader_SalesOrderID] PRIMARY KEY ([SalesOrderID] ASC)
GO

-- DROP TABLE FactSales
-- TRUNCATE TABLE FactSales


DECLARE @i INT = 1;
DECLARE @max INT = 1000;

WHILE @i <= @max
BEGIN
    INSERT INTO [dbo].[FactSales] (
        [OrderDate],
        [PurchaseOrderNumber],
        [CustomerID],
        [Total],
        [rowguid],
        [ModifiedDate]
    )
    VALUES (
        DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 365), GETDATE()), -- Random date in last year
       'PO' + RIGHT('00000' + CAST(@i AS VARCHAR(5)), 5),  
        1 + ABS(CHECKSUM(NEWID()) % 100), -- Random CustomerID between 1 and 100
        ROUND(100 + (RAND(CHECKSUM(NEWID())) * 9900), 2), -- Random Total between 100.00 and 10000.00
        NEWID(),
        GETDATE()
    );
    SET @i = @i + 1;
END

select * from FactSales;


-- Forcing a specific day
DECLARE @i INT = 1;
DECLARE @max INT = 100;
DECLARE @day INT = 1

WHILE @i <= 100
BEGIN
    INSERT INTO [dbo].[FactSales] (
        [OrderDate],
        [PurchaseOrderNumber],
        [CustomerID],
        [Total],
        [rowguid],
        [ModifiedDate]
    )
    VALUES (
        DATEADD(DAY, @day, GETDATE()), -- Random date in last year
       'PO' + RIGHT('00000' + CAST(@i AS VARCHAR(5)), 5),  
        1 + ABS(CHECKSUM(NEWID()) % 100), -- Random CustomerID between 1 and 100
        ROUND(100 + (RAND(CHECKSUM(NEWID())) * 9900), 2), -- Random Total between 100.00 and 10000.00
        NEWID(),
        GETDATE()
    );
    SET @i = @i + 1;
END

SELECT * FROM FactSales
WHERE OrderDate >= getdate();

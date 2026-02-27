IF OBJECT_ID('SalesLT.SalesOrderHeaderBig') IS NOT NULL
	DROP TABLE SalesLT.SalesOrderHeaderBig;
GO

CREATE TABLE SalesLT.SalesOrderHeaderBig
	(
	[SalesOrderID] [int] IDENTITY(1,1) NOT NULL,
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	OnlineOrderFlag BIT NOT NULL,
	SalesOrderNumber AS (isnull(N'SO'+CONVERT([nvarchar](23),[SalesOrderID],0),N'*** ERROR ***')),
	PurchaseOrderNumber NVARCHAR(25) NULL,
	AccountNumber NVARCHAR(25) NULL,
	CustomerID int NOT NULL,	
	[ShipToAddressID] [int] NULL,
	[BillToAddressID] [int] NULL,
	[ShipMethod] [nvarchar](50) NOT NULL,
	CreditCardID int NULL,
	CreditCardApprovalCode VARCHAR(15) NULL,	
	SubTotal money NOT NULL,
	TaxAmt money NOT NULL,
	Freight money NOT NULL,
	TotalDue AS (isnull(([SubTotal]+[TaxAmt])+[Freight],(0))),
	Comment nvarchar(128) NULL,
	rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
	ModifiedDate datetime NOT NULL
	)  ON [PRIMARY]
GO

SET IDENTITY_INSERT SalesLT.SalesOrderHeaderBig ON
GO
INSERT INTO SalesLT.SalesOrderHeaderBig (SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber
    , CustomerID, BillToAddressID, ShipToAddressID, ShipMethod, CreditCardApprovalCode,  SubTotal, TaxAmt, Freight, Comment, rowguid, ModifiedDate)
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber
    , CustomerID, BillToAddressID, ShipToAddressID, ShipMethod, CreditCardApprovalCode,  SubTotal, TaxAmt, Freight, Comment, rowguid, ModifiedDate 
FROM SalesLT.SalesOrderHeader
GO
SET IDENTITY_INSERT SalesLT.SalesOrderHeaderBig OFF
GO


IF OBJECT_ID('SalesLT.SalesOrderDetailBig') IS NOT NULL
	DROP TABLE SalesLT.SalesOrderDetailBig;
GO

CREATE TABLE SalesLT.SalesOrderDetailBig
	(
	SalesOrderID int NOT NULL,
	SalesOrderDetailID int NOT NULL IDENTITY (1, 1),	
	OrderQty smallint NOT NULL,
	ProductID int NOT NULL,	
	UnitPrice money NOT NULL,
	UnitPriceDiscount money NOT NULL,
	LineTotal  AS (isnull(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
	rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
	ModifiedDate datetime NOT NULL
	)  ON [PRIMARY]
GO

SET IDENTITY_INSERT SalesLT.SalesOrderDetailBig ON
GO
INSERT INTO SalesLT.SalesOrderDetailBig (SalesOrderID, SalesOrderDetailID,  OrderQty, ProductID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
SELECT SalesOrderID, SalesOrderDetailID, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate 
FROM SalesLT.SalesOrderDetail WITH (HOLDLOCK TABLOCKX)
GO
SET IDENTITY_INSERT SalesLT.SalesOrderDetailBig OFF
GO


-- Make tables bigger
BEGIN TRANSACTION

DECLARE @TableVar TABLE
(OrigSalesOrderID int, NewSalesOrderID int)

INSERT INTO SalesLT.SalesOrderHeaderBig 
	(RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
	 PurchaseOrderNumber, AccountNumber, CustomerID, BillToAddressID, ShipToAddressID, ShipMethod,  
	 CreditCardApprovalCode, SubTotal, TaxAmt, Freight, Comment, 
	 rowguid, ModifiedDate)
OUTPUT cast(inserted.Comment as INT), inserted.SalesOrderID
	INTO @TableVar
SELECT
     RevisionNumber
     , DATEADD(dd, number, OrderDate) AS OrderDate
     , DATEADD(dd, number, DueDate) AS DueDate
     , DATEADD(dd, number, ShipDate) AS ShipDate
    , Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber
    , CustomerID, BillToAddressID, ShipToAddressID, ShipMethod, CreditCardApprovalCode, SubTotal, TaxAmt, Freight
    , SalesOrderID as Comment
    , NEWID()
    , DATEADD(dd, number, ModifiedDate) AS ModifiedDate    
FROM SalesLT.SalesOrderHeader AS SOH
CROSS JOIN (
	select top 10000 (row_number() over (order by t1.object_id) % 365) AS Number
    from sys.objects t1 
    cross join sys.objects t2    
) AS R
ORDER BY OrderDate, number

-- select * from @TableVar

INSERT INTO SalesLT.SalesOrderDetailBig 
	(SalesOrderID, OrderQty, ProductID, 
	 UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
SELECT 
	tv.NewSalesOrderID, OrderQty, ProductID, 
	UnitPrice, UnitPriceDiscount, NEWID(), ModifiedDate 
FROM SalesLT.SalesOrderDetail AS sod
JOIN @TableVar AS tv
	ON sod.SalesOrderID = tv.OrigSalesOrderID
ORDER BY sod.SalesOrderDetailID

COMMIT

select count(*) from SalesLT.SalesOrderDetailBig;
select count(*) from SalesLT.SalesOrderHeaderBig;

--SELECT * FROM SalesLT.SalesOrderDetail
--SELECT * FROM AdventureWorks.Sales.SalesOrderDetail
--select * from SalesLT.SalesOrderDetailBig
--select * from SalesLT.SalesOrderHeaderBig
/*
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber
    , CustomerID, BillToAddressID, ShipToAddressID, CreditCardApprovalCode,  SubTotal, TaxAmt, Freight
    , Comment, rowguid, ModifiedDate 
FROM SalesLT.SalesOrderHeader

-- SalesPersonID, TerritoryID, ShipMethodID, CreditCardID, CurrencyRateID,


*/
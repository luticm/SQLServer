/*****************************************************************************
*   FileName:  Create Big AdventureWorks Tables.sql
*
*   Summary: Creates an Big version of the AdventureWorks database
*            for use in demonstrating SQL Server performance tuning and
*            execution plan issues.
*
*   Date: November 14, 2011 
*
*   SQL Server Versions:
*         2008, 2008R2, 2012
*         
******************************************************************************
*   Copyright (C) 2011 Jonathan M. Kehayias, SQLskills.com
*   All rights reserved. 
*
*   For more scripts and sample code, check out 
*      http://sqlskills.com/blogs/jonathan
*
*   You may alter this code for your own *non-commercial* purposes. You may
*   republish altered code as long as you include this copyright and give 
*	due credit. 
*
*
*   THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
*   ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
*   TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
*   PARTICULAR PURPOSE. 
*
******************************************************************************/

-- Modified on 2025-10-29


USE AdventureWorksBig;
GO

IF OBJECT_ID('Sales.SalesOrderHeaderBig') IS NOT NULL
	DROP TABLE Sales.SalesOrderHeaderBig;
GO

CREATE TABLE Sales.SalesOrderHeaderBig
	(
	SalesOrderID int NOT NULL IDENTITY (1, 1) NOT FOR REPLICATION,
	RevisionNumber tinyint NOT NULL,
	OrderDate datetime NOT NULL,
	DueDate datetime NOT NULL,
	ShipDate datetime NULL,
	Status tinyint NOT NULL,
	OnlineOrderFlag dbo.Flag NOT NULL,
	SalesOrderNumber  AS (isnull(N'SO'+CONVERT([nvarchar](23),[SalesOrderID],0),N'*** ERROR ***')),
	PurchaseOrderNumber dbo.OrderNumber NULL,
	AccountNumber dbo.AccountNumber NULL,
	CustomerID int NOT NULL,
	SalesPersonID int NULL,
	TerritoryID int NULL,
	BillToAddressID int NOT NULL,
	ShipToAddressID int NOT NULL,
	ShipMethodID int NOT NULL,
	CreditCardID int NULL,
	CreditCardApprovalCode varchar(15) NULL,
	CurrencyRateID int NULL,
	SubTotal money NOT NULL,
	TaxAmt money NOT NULL,
	Freight money NOT NULL,
	TotalDue  AS (isnull(([SubTotal]+[TaxAmt])+[Freight],(0))),
	Comment nvarchar(128) NULL,
	rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
	ModifiedDate datetime NOT NULL
	)  ON [PRIMARY]
GO

SET IDENTITY_INSERT Sales.SalesOrderHeaderBig ON
GO
INSERT INTO Sales.SalesOrderHeaderBig (SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight, Comment, rowguid, ModifiedDate)
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight, Comment, rowguid, ModifiedDate 
FROM Sales.SalesOrderHeader WITH (HOLDLOCK TABLOCKX)
GO
SET IDENTITY_INSERT Sales.SalesOrderHeaderBig OFF
GO

ALTER TABLE Sales.SalesOrderHeaderBig ADD CONSTRAINT
	PK_SalesOrderHeaderBig_SalesOrderID PRIMARY KEY CLUSTERED 
	(
	SalesOrderID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO

CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderHeaderBig_rowguid ON Sales.SalesOrderHeaderBig
	(
	rowguid
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderHeaderBig_SalesOrderNumber ON Sales.SalesOrderHeaderBig
	(
	SalesOrderNumber
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderBig_CustomerID ON Sales.SalesOrderHeaderBig
	(
	CustomerID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderBig_SalesPersonID ON Sales.SalesOrderHeaderBig
	(
	SalesPersonID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF OBJECT_ID('Sales.SalesOrderDetailBig') IS NOT NULL
	DROP TABLE Sales.SalesOrderDetailBig;
GO

CREATE TABLE Sales.SalesOrderDetailBig
	(
	SalesOrderID int NOT NULL,
	SalesOrderDetailID int NOT NULL IDENTITY (1, 1),
	CarrierTrackingNumber nvarchar(25) NULL,
	OrderQty smallint NOT NULL,
	ProductID int NOT NULL,
	SpecialOfferID int NOT NULL,
	UnitPrice money NOT NULL,
	UnitPriceDiscount money NOT NULL,
	LineTotal  AS (isnull(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
	rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
	ModifiedDate datetime NOT NULL
	)  ON [PRIMARY]
GO

SET IDENTITY_INSERT Sales.SalesOrderDetailBig ON
GO
INSERT INTO Sales.SalesOrderDetailBig (SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
SELECT SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate 
FROM Sales.SalesOrderDetail WITH (HOLDLOCK TABLOCKX)
GO
SET IDENTITY_INSERT Sales.SalesOrderDetailBig OFF
GO

ALTER TABLE Sales.SalesOrderDetailBig ADD CONSTRAINT
	PK_SalesOrderDetailBig_SalesOrderID_SalesOrderDetailID PRIMARY KEY CLUSTERED 
	(
	SalesOrderID,
	SalesOrderDetailID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderDetailBig_rowguid ON Sales.SalesOrderDetailBig
	(
	rowguid
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_SalesOrderDetailBig_ProductID ON Sales.SalesOrderDetailBig
	(
	ProductID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


BEGIN TRANSACTION


DECLARE @TableVar TABLE
(OrigSalesOrderID int, NewSalesOrderID int)

INSERT INTO Sales.SalesOrderHeaderBig 
	(RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
	 PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, 
	 BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, 
	 CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight, Comment, 
	 rowguid, ModifiedDate)
OUTPUT inserted.Comment, inserted.SalesOrderID
	INTO @TableVar
SELECT RevisionNumber, DATEADD(dd, number, OrderDate) AS OrderDate, 
	 DATEADD(dd, number, DueDate),  DATEADD(dd, number, ShipDate), 
	 Status, OnlineOrderFlag, 
	 PurchaseOrderNumber, 
	 AccountNumber, 
	 CustomerID, SalesPersonID, TerritoryID, BillToAddressID, 
	 ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, 
	 CurrencyRateID, SubTotal, TaxAmt, Freight, SalesOrderID, 
	 NEWID(), DATEADD(dd, number, ModifiedDate)
FROM Sales.SalesOrderHeader AS soh WITH (HOLDLOCK TABLOCKX)
CROSS JOIN (
		SELECT number
		FROM (	SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
		  ) AS tab
) AS Randomizer
ORDER BY OrderDate, number

INSERT INTO Sales.SalesOrderDetailBig 
	(SalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, 
	 SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
SELECT 
	tv.NewSalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, 
	SpecialOfferID, UnitPrice, UnitPriceDiscount, NEWID(), ModifiedDate 
FROM Sales.SalesOrderDetail AS sod
JOIN @TableVar AS tv
	ON sod.SalesOrderID = tv.OrigSalesOrderID
ORDER BY sod.SalesOrderDetailID

COMMIT
/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 07 Demo 04 - Estatísticas
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE AdventureWorks2012
GO

select * from Sales.SalesOrderHeader
select * from Sales.SalesOrderDetail

exec sp_help 'sales.salesorderheader'
EXEC SP_HELPSTATS 'sales.salesorderheader', 'ALL'

DBCC SHOW_STATISTICS ('sales.salesorderheader', OrderDate)
GO

SELECT COUNT(DISTINCT ORDERDATE)
FROM Sales.SalesOrderHeader

DBCC SHOW_STATISTICS ('sales.salesorderheader', PK_SalesOrderHeader_SalesOrderID)
GO

exec sp_help 'sales.salesorderdetail'

DBCC SHOW_STATISTICS ('sales.salesorderdetail', PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID)
go

select *
from Sales.SalesOrderDetail
where SalesOrderID = 45032
go

dbcc freeproccache
go

select *
from Sales.SalesOrderDetail
where SalesOrderID = 44288
go

DECLARE @i INT
SET @i = 44288

select *
from Sales.SalesOrderDetail
where SalesOrderID = @i
go

/*
DROP INDEX Sales.SalesOrderHeader.idx_testeEstatistica
DROP INDEX Sales.SalesOrderHeader.idx_testeEstatistica2
DROP INDEX Sales.SalesOrderHeader.idx_testeEstatistica3
DROP INDEX Sales.SalesOrderHeader.idx_testeEstatistica4
DROP INDEX Sales.SalesOrderHeader.idx_testeEstatistica5
*/


CREATE NONCLUSTERED INDEX idx_testeEstatistica
ON Sales.SalesOrderHeader (SalesPersonId, TerritoryID, OrderDate, Status, PurchaseOrderNumber)
go

DBCC SHOW_STATISTICS ('sales.salesorderheader', idx_testeEstatistica)
go

CREATE NONCLUSTERED INDEX idx_testeEstatistica2
ON Sales.SalesOrderHeader (OrderDate, SalesPersonId, TerritoryID, Status, PurchaseOrderNumber)
go

DBCC SHOW_STATISTICS ('sales.salesorderheader', idx_testeEstatistica2)
go

CREATE NONCLUSTERED INDEX idx_testeEstatistica3
ON Sales.SalesOrderHeader (PurchaseOrderNumber, SalesPersonId, TerritoryID, Status, OrderDate)
go

DBCC SHOW_STATISTICS ('sales.salesorderheader', idx_testeEstatistica3)
go

CREATE NONCLUSTERED INDEX idx_testeEstatistica4
ON Sales.SalesOrderHeader (PurchaseOrderNumber)
go

DBCC SHOW_STATISTICS ('sales.salesorderheader', idx_testeEstatistica4)
GO

SELECT * FROM sys.indexes




SELECT * FROM Person.Person
GO

-- Default STATS
EXEC SP_HELPSTATS 'sales.salesorderheader'
EXEC SP_HELPSTATS 'Person.Person'

EXEC SP_HELPSTATS 'Person.Person', 'ALL'

CREATE STATISTICS StatsTeste ON Person.Person (FirstName, LastName)
WITH SAMPLE 50 PERCENT
GO

DBCC SHOW_STATISTICS ('Person.Person', StatsTeste)
go

SELECT 
	STATS_DATE(object_id, stats_id) as data,
	*
FROM sys.stats
WHERE object_id = OBJECT_ID('sales.salesorderheader')
GO

SELECT *
FROM SYS.stats_columns
GO

UPDATE STATISTICS sales.salesorderheader
WITH FULLSCAN
GO

DROP STATISTICS Person.Person.StatsTeste
go











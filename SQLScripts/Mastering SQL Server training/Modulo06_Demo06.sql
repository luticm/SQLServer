/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: MasteringCS the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 06 - ColumnStore Indexes
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

-- CREATE DATABASE CSINDEX

--IF (DB_ID('MasteringCS') IS NOT NULL)
--	DROP DATABASE MasteringCS
--GO

--CREATE DATABASE MasteringCS
--  ON PRIMARY 
--	(NAME = N'MasteringCS_Data01', 
--	FILENAME = N'G:\Temp\MasteringCS_Data01.mdf',
--	SIZE = 1GB,
--	MAXSIZE = 100GB,
--	FILEGROWTH = 1GB)
--  LOG ON 
--  (NAME = N'MasteringCS_Log', 
--	FILENAME = N'G:\Temp\MasteringCS_log.ldf',
--	SIZE = 500MB,
--	MAXSIZE = 30GB,
--	FILEGROWTH = 500MB)	
--go


/*****************************************************************************************	
	Demo 06.01) ColumnsStore Index
*****************************************************************************************/
USE CSIndex
GO
SET NOCOUNT ON;
GO

IF OBJECT_ID('OrdersReallyBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersReallyBig
END
GO
SELECT TOP 50000000 IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate1,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate2,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate3,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value1,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value2,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value3
  INTO OrdersReallyBig
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
GO

SELECT *
INTO CustomersBig
FROM Northwind.dbo.Customers
go

CREATE UNIQUE CLUSTERED INDEX idxCL_CustomersBig_ID
ON dbo.CustomersBig (CustomerID)
go

-- DBCC LOGINFO()

-- 12:00
ALTER TABLE OrdersReallyBig ADD CONSTRAINT xpk_OrdersReallyBig PRIMARY KEY(OrderID)
GO

CREATE NONCLUSTERED INDEX idxNCL_OrdersReallyBig_CustomerID
ON OrdersReallyBig (CustomerID)
go

CREATE NONCLUSTERED INDEX idxNCL_OrdersReallyBig_OrderDate1
ON OrdersReallyBig (OrderDate1)
go

CREATE NONCLUSTERED INDEX idxNCL_OrdersReallyBig_Value1
ON OrdersReallyBig (Value1)
go

-- DROP INDEX ix_1 ON OrdersReallyBig
-- 11:43
CREATE COLUMNSTORE INDEX idxNCL_ColumnStore 
ON OrdersReallyBig(OrderID, CustomerID, OrderDate1, OrderDate2, OrderDate3, Value1, Value2, Value3)
GO





-- Quantidade de registros e tamanho dos índices...
SELECT 
	OBJECT_NAME(P.object_id) AS Nome
	, P.index_id
	, P.rows
	, P.data_compression_desc
	, AU.type_desc
	, AU.total_pages
	, AU.used_pages
	, AU.data_pages
	, AU.first_page
	, AU.root_page
	, AU.first_iam_page
	-- , P.* , AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('OrdersReallyBig')
go


DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
-- Tempo 2:25
SELECT CustomersBig.ContactName,
       SUM(OrdersReallyBig.Value1) AS ValorTotal
  FROM OrdersReallyBig
 INNER JOIN CustomersBig
    ON OrdersReallyBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName like 'Ana%'
   AND OrdersReallyBig.Value1 < 1000
   AND OrdersReallyBig.Value2 BETWEEN 0 AND 900000
   AND OrdersReallyBig.Value3 BETWEEN 0 AND 900000
   AND OrdersReallyBig.OrderDate1 < '29990101'
 GROUP BY CustomersBig.ContactName
OPTION (IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX)
GO

DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
go

SELECT CustomersBig.ContactName,
       SUM(OrdersReallyBig.Value1) AS ValorTotal	   
  FROM OrdersReallyBig
 INNER JOIN CustomersBig
    ON OrdersReallyBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName like 'Ana%'
   AND OrdersReallyBig.Value1 < 1000
   AND OrdersReallyBig.Value2 BETWEEN 0 AND 900000
   AND OrdersReallyBig.Value3 BETWEEN 0 AND 900000
   AND OrdersReallyBig.OrderDate1 < '29990101'
 GROUP BY CustomersBig.ContactName 
GO

SELECT COUNT(OrderDate1)
FROM OrdersReallyBig WITH (INDEX(ix_1))
WHERE OrdersReallyBig.OrderDate1 < '23990101'

select * from sys.dm_os_memory_clerks
order by pages_kb DESC

SELECT *
FROM sys.dm_os_buffer_descriptors
go

-- Consulta o tamanho dos índices
SELECT Object_Name(p.Object_Id) As Tabela,
       I.Name As Indice, 
       Total_Pages,
       Total_Pages * 8 / 1024.00 As MB,
	   p.*, a.*
  FROM sys.Partitions AS P
 INNER JOIN sys.Allocation_Units AS A 
    ON P.partition_id = A.Container_Id
 INNER JOIN sys.Indexes AS I 
    ON P.object_id = I.object_id 
   AND P.index_id = I.index_id
 WHERE p.Object_Id = Object_Id('OrdersReallyBig')
	AND Total_Pages > 0
GO










/*****************************************************************************************	
	Demo 06.02) ColumnsStore Index
*****************************************************************************************/
USE MASTER
GO

IF EXISTS (SELECT * FROM SYSDATABASES WHERE [Name] = 'MasteringCS')
BEGIN
	DROP DATABASE MasteringCS
END
GO

CREATE DATABASE MasteringCS
GO

USE MasteringCS
GO

IF OBJECT_ID('dbo.TabelaBase', 'U') IS NOT NULL
	DROP TABLE dbo.TabelaBase
GO

CREATE TABLE dbo.TabelaBase (
	ID INT IDENTITY NOT NULL PRIMARY KEY
	, Nome VARCHAR(100) NOT NULL DEFAULT ('Sr. Nimbus')
	, DataRegistro DATETIME2 NOT NULL DEFAULT(SYSDATETIME())
	, GUIDzao VARCHAR(100) NOT NULL DEFAULT (CAST(NEWID() AS VARCHAR(100)))
	, Numero INT NOT NULL DEFAULT(100)
)
GO

SET NOCOUNT ON;

INSERT INTO dbo.TabelaBase DEFAULT VALUES
GO 2000000

SELECT
	OBJECT_NAME(object_id) AS ObjectName 
	, AU.* 
	, P.*
FROM SYS.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID IN (object_id('TabelaBase'))
ORDER BY object_id, type
GO

CREATE COLUMNSTORE INDEX idxNCL_TabelaBase_ColumnStore 
ON TabelaBase(ID, Nome, DataRegistro, GUIDzao, Numero)
GO


SELECT
	OBJECT_NAME(object_id) AS ObjectName 
	, AU.* 
	, P.*
FROM SYS.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID IN (object_id('TabelaBase'))
ORDER BY object_id, type
GO

-- Dicionário primário e secundários
SELECT *
FROM sys.column_store_dictionaries
go

SELECT *
FROM sys.column_store_segments
go

SET STATISTICS IO ON

DBCC DROPCLEANBUFFERS()
GO

SELECT SUM(ID * 1.0)
FROM dbo.TabelaBase
OPTION (IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX)
GO

SELECT SUM(ID * 1.0)
FROM dbo.TabelaBase
go

SELECT SUM(Numero * 1.0)
FROM dbo.TabelaBase
OPTION (IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX)
GO

SELECT SUM(Numero * 1.0)
FROM dbo.TabelaBase
go

DBCC TRACEON(3604)
DBCC PAGE (MasteringCS, 1, 313, 2)
GO

/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 08 - Plan Cache parte 2
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/
USE Northwind
go

/*
	Contexto de execução -> múltiplos planos em cache
*/
-- Procedimento
DBCC FREEPROCCACHE
go

IF OBJECT_ID('dbo.usp_CustCities') IS NOT NULL
  DROP PROC dbo.usp_CustCities
GO

CREATE PROC dbo.usp_CustCities
AS

	SELECT CustomerID, Country, Region, City,
	  Country + '.' + Region + '.' + City AS CRC
	FROM dbo.Customers
	ORDER BY Country, Region, City
GO

SELECT * FROM dbo.Customers

-- Execução
-- Olhe o resultado do CRC
EXEC dbo.usp_CustCities
GO

-- Em cache temos...
SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- Altera uma configuração de sessão
SET CONCAT_NULL_YIELDS_NULL OFF
GO
EXEC dbo.usp_CustCities
GO

-- O que mudou entre os resultados?

-- O que está em cache???
SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO
-- O que muda entre os registros em cache?

-- Olhemos então o syscacheobjects, setopts
SELECT *
FROM sys.syscacheobjects
order by sql
-- Eles mudam, incrível...


-- Olhe que a DMV agora é diferente
SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_plan_attributes(cp.plan_handle)
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
ORDER BY text
GO

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_plan_attributes(cp.plan_handle)
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
WHERE attribute = 'set_options'
ORDER BY text
GO

-- limpeza
SET CONCAT_NULL_YIELDS_NULL ON
GO

IF OBJECT_ID('dbo.usp_CustCities') IS NOT NULL
  DROP PROC dbo.usp_CustCities
GO

EXEC sp_configure 



/*
	STATISTICS RECOMPILE
*/
DBCC FREEPROCCACHE

USE Northwind
GO
IF OBJECT_ID('dbo.usp_GetOrders') IS NOT NULL
  DROP PROC dbo.usp_GetOrders
GO

CREATE PROC dbo.usp_GetOrders
  @odate AS DATETIME
AS

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= @odate
GO

-- Já sabem o que esperar, não é?
EXEC dbo.usp_GetOrders '19980506'
GO

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

EXEC dbo.usp_GetOrders '19960101'
GO

-- OK?
SELECT *
FROM sys.indexes
WHERE OBJECT_ID =  OBJECT_ID('Orders')
go

SELECT *
FROM sys.sysindexes
WHERE id =  OBJECT_ID('Orders')
go

SELECT * FROM Orders
GO

UPDATE Orders
SET OrderDate = OrderDate
WHERE OrderID < 10254
GO

SELECT *
FROM sys.sysindexes
WHERE id =  OBJECT_ID('Orders')
go

SELECT *
FROM sys.system_internals_partition_columns
go

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

EXEC dbo.usp_GetOrders '19960101'
GO

UPDATE Orders
SET OrderDate = OrderDate
GO

DBCC SHOW_STATISTICS(Orders, ORDERDATE)

SELECT *
FROM sys.sysindexes
WHERE id =  OBJECT_ID('Orders')
go

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- O que teremos agora?
EXEC dbo.usp_GetOrders '19960101'
GO
-- Veja o plano de execução
-- Se quiser, monitore o evento SP:Recompile com o Profiler

-- Interessante foi ver o usecount
SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

SELECT *
FROM sys.dm_exec_query_stats AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

SELECT *
FROM sys.sysindexes
WHERE id =  OBJECT_ID('Orders')
go

-- http://sqlblog.com/blogs/paul_white/archive/2011/09/21/how-to-find-the-statistics-used-to-compile-an-execution-plan.aspx
-- http://blogs.msdn.com/b/saponsqlserver/archive/2011/09/07/changes-to-automatic-update-statistics-in-sql-server-traceflag-2371.aspx



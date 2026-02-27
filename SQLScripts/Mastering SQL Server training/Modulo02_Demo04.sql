/****************************************************************************************
*****************************************************************************************
			 
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 02 - Demo 04 - Problema com XEvents no SQL Server 2008 R2 e pressão na memória
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE master
GO

SELECT @@VERSION
-- Microsoft SQL Server 2008 R2 (SP1) - 10.50.2550.0 (X64) 


/*
CREATE DATABASE MemUsage
GO

USE MemUsage
GO

IF OBJECT_ID('dbo.TabelaBase', 'U') IS NOT NULL
	DROP TABLE dbo.TabelaBase
GO

CREATE TABLE dbo.TabelaBase (
	ID INT IDENTITY NOT NULL PRIMARY KEY
	, Nome CHAR(8000) NOT NULL DEFAULT ('Sr. Nimbus')
	, DataRegistro DATETIME2 NOT NULL DEFAULT(SYSDATETIME())
)
GO

INSERT INTO dbo.TabelaBase DEFAULT VALUES
GO 100000
*/

-- Pressão na memória
sp_configure 'max server', '1250'
RECONFIGURE

SELECT COUNT(*)
FROM AdventureWorks2008R2.Sales.SalesOrderDetail WITH(INDEX(1))
SELECT COUNT(*)
FROM AdventureWorks2008R2.Sales.SalesOrderHeader WITH(INDEX(1))
SELECT COUNT(*)
FROM MemUsage.dbo.TabelaBase WITH(INDEX(1))
go

SELECT TOP 30 *
FROM sys.dm_os_memory_clerks
order by single_pages_kb desc
GO

-- xEvent para monitorar MemUsage
SELECT * FROM sys.databases
WHERE name = 'MemUsage'

-- dbid = 50

USE [master];
GO

DROP EVENT SESSION FindBlockers ON SERVER

CREATE EVENT SESSION FindBlockers ON SERVER
ADD EVENT sqlserver.lock_acquired
    (action
        ( sqlserver.sql_text, sqlserver.database_id, sqlserver.tsql_stack,
         sqlserver.plan_handle, sqlserver.session_id)
    WHERE ( database_id=50 AND resource_0!=0)
    ),
ADD EVENT sqlserver.lock_released
    (WHERE ( database_id=50 AND resource_0!=0 ))
ADD TARGET package0.pair_matching 
    ( SET begin_event='sqlserver.lock_acquired',
            begin_matching_columns='database_id, resource_0, resource_1, resource_2, transaction_id, mode',
            end_event='sqlserver.lock_released',
            end_matching_columns='database_id, resource_0, resource_1, resource_2, transaction_id, mode',
    respond_to_memory_pressure=1)
WITH (max_dispatch_latency = 1 seconds);
GO

ALTER EVENT SESSION FindBlockers
ON SERVER
STATE = START;
GO

SELECT name, target_name, CAST(xet.target_data AS xml)
  FROM sys.dm_xe_session_targets AS xet
  JOIN sys.dm_xe_sessions AS xe
     ON (xe.address = xet.event_session_address)
GO

ALTER EVENT SESSION FindBlockers
ON SERVER
STATE = STOP;
GO

USE MemUsage
GO

SELECT * FROM dbo.TabelaBase
WHERE ID < 10000

BEGIN TRANSACTION

	UPDATE TabelaBase WITH (ROWLOCK)
		SET DataRegistro = DataRegistro
	WHERE ID < 10000

COMMIT
GO

ALTER EVENT SESSION FindBlockers
ON SERVER
STATE = START;
GO

SELECT *
FROM sys.dm_os_memory_cache_clock_hands
ORDER BY rounds_count DESC
go

SELECT TOP 30 *
FROM sys.dm_os_memory_clerks
order by single_pages_kb desc
GO

SELECT ((COUNT(*) * 8192) / 1024.0 / 1024.0) AS MB
FROM sys.dm_os_buffer_descriptors
go

BEGIN TRANSACTION

	UPDATE TabelaBase WITH (ROWLOCK)
		SET DataRegistro = DataRegistro
	WHERE ID < 10000

COMMIT
GO 20
GO 50
GO 50

SELECT TOP 30 *
FROM sys.dm_os_memory_clerks
order by single_pages_kb desc
GO

SELECT ((COUNT(*) * 8192) / 1024.0 / 1024.0) AS MB
FROM sys.dm_os_buffer_descriptors
go

SELECT *
FROM sys.dm_os_memory_cache_clock_hands
ORDER BY rounds_count DESC
go

SELECT name, target_name, CAST(xet.target_data AS xml)
  FROM sys.dm_xe_session_targets AS xet
  JOIN sys.dm_xe_sessions AS xe
     ON (xe.address = xet.event_session_address)
GO

DROP EVENT SESSION FindBlockers ON SERVER


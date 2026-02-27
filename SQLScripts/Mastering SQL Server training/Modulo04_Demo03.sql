/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 04 - Demo 03 - Indirect Checkpoint (casa)
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

use master
go

IF DB_ID('Mastering') IS NOT NULL
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
ON PRIMARY
(NAME = 'Mastering',
	FILENAME = 'C:\Temp\Mastering.mdf',
	SIZE = 10GB)
	LOG ON
	(NAME = 'Mastering_Log',
	FILENAME = 'C:\Temp\Mastering.ldf',
	SIZE = 10GB)
go

USE Mastering
GO

BACKUP DATABASE Mastering
TO DISK = 'C:\Temp\Mastering.bak'
WITH COMPRESSION, INIT, FORMAT
go

checkpoint

-- Monitorando...
IF EXISTS(
	SELECT *
	FROM sys.server_event_sessions
	WHERE name = 'xMonitor'
)
	DROP EVENT SESSION xMonitor
	ON SERVER
go

CREATE EVENT SESSION xMonitor
ON SERVER
	ADD EVENT sqlserver.checkpoint_end	
	ADD TARGET package0.ring_buffer
go

ALTER EVENT SESSION xMonitor
ON SERVER
STATE = START
GO

SELECT name, target_name, CAST(xet.target_data AS xml)
  FROM sys.dm_xe_session_targets AS xet
  JOIN sys.dm_xe_sessions AS xe
     ON (xe.address = xet.event_session_address)
GO

SELECT *
INTO dbo.TesteCheckpoint
FROM AdventureWorks2012.Sales.SalesOrderDetail
GO

INSERT dbo.TesteCheckpoint
SELECT  
        T.SalesOrderDetailID ,
        T.CarrierTrackingNumber ,
        T.OrderQty ,
        T.ProductID ,
        T.SpecialOfferID ,
        T.UnitPrice ,
        T.UnitPriceDiscount ,
        T.LineTotal ,
        T.rowguid ,
        T.ModifiedDate
FROM AdventureWorks2012.Sales.SalesOrderDetail AS T
WAITFOR DELAY '00:00:02'
GO 300

SELECT COUNT(*) FROM dbo.TesteCheckpoint
go

-- 23 checkpoints
SELECT name, target_name, CAST(xet.target_data AS xml)
  FROM sys.dm_xe_session_targets AS xet
  JOIN sys.dm_xe_sessions AS xe
     ON (xe.address = xet.event_session_address)
GO

CHECKPOINT
GO

ALTER EVENT SESSION xMonitor
ON SERVER
STATE = STOP
GO




use master
go

IF DB_ID('Mastering') IS NOT NULL
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
ON PRIMARY
(NAME = 'Mastering',
	FILENAME = 'C:\Temp\Mastering.mdf',
	SIZE = 3GB)
	LOG ON
	(NAME = 'Mastering_Log',
	FILENAME = 'C:\Temp\Mastering.ldf',
	SIZE = 3GB)
go

USE Mastering
GO

ALTER DATABASE Mastering
SET TARGET_RECOVERY_TIME = 5 SECONDS;
GO

SELECT target_recovery_time_in_seconds, *
FROM SYS.databases
GO

BACKUP DATABASE Mastering
TO DISK = 'C:\Temp\Mastering.bak'
WITH COMPRESSION, INIT, FORMAT
go

ALTER EVENT SESSION xMonitor
ON SERVER
STATE = START
GO

SELECT *
INTO dbo.TesteCheckpoint
FROM AdventureWorks2012.Sales.SalesOrderDetail
GO
INSERT dbo.TesteCheckpoint
SELECT  
        T.SalesOrderDetailID ,
        T.CarrierTrackingNumber ,
        T.OrderQty ,
        T.ProductID ,
        T.SpecialOfferID ,
        T.UnitPrice ,
        T.UnitPriceDiscount ,
        T.LineTotal ,
        T.rowguid ,
        T.ModifiedDate
FROM AdventureWorks2012.Sales.SalesOrderDetail AS T
WAITFOR DELAY '00:00:02'
GO 300

-- 111 checkpoints
SELECT name, target_name, CAST(xet.target_data AS xml)
  FROM sys.dm_xe_session_targets AS xet
  JOIN sys.dm_xe_sessions AS xe
     ON (xe.address = xet.event_session_address)
GO

ALTER EVENT SESSION xMonitor
ON SERVER
STATE = STOP
GO
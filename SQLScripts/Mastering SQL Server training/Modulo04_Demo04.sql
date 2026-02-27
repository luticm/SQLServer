/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 04 - Demo 04 - Simple
	Descrição: Vamos quebrar o mito do RECOVERY MODEL SIMPLE
		E mostrar como o desenvolvedor pode atrapalhar a vida do DBA...
		
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
 FILENAME = 'D:\Temp\SQLData\Mastering.mdf',
 SIZE = 15MB)
 LOG ON
 (NAME = 'Mastering_Log',
 FILENAME = 'D:\Temp\SQLData\Mastering.ldf',
 SIZE = 2MB)
go

SELECT
	database_id,
	name,
	recovery_model_desc
FROM master.sys.databases
WHERE name = 'Mastering'
go

USE Mastering
go

IF (OBJECT_ID('TabelaLog') IS NOT NULL)
	DROP TABLE TabelaLog
go

CREATE TABLE TabelaLog
(Codigo INT IDENTITY NOT NULL, 
 Nome VARCHAR(1000) NOT NULL,
 PADDING CHAR(100) NOT NULL)
go

--DBCC TRACEON(3604)
--DBCC TRACEON(3004)

-- Criar a tabela usando script dos nomes

INSERT INTO TabelaLog
SELECT	
	(MC.name + XO.Name) AS Nome,
	'Sr. Nimbus'
FROM sys.dm_os_memory_clerks AS MC
CROSS JOIN sys.dm_xe_objects AS XO
go

SELECT COUNT(*) FROM TabelaLog
go

dbcc loginfo()


-- 0000009f:00000010:0117
select *
from ::fn_dblog(null, null)

checkpoint

dbcc loginfo()


/*
	Analisar o tamanho do log e o tamanho do mdf.
	
	P1: Porque eles estão com esse tamanho?
	P2: Se eu tentar encolher o log, vai funcionar? Sim, não e pq?
*/
DBCC LOGINFO()
CHECKPOINT

DBCC SHRINKFILE('Mastering_Log', 5)
go


/*
	R1: Dados crescimento normal, log devido ao tamanho da transação que não permitia o log circular.
	R2: Auto truncate
*/
 dbcc traceon(3604)
 dbcc traceon(3004)

-- Vamos sair do AutoTruncate mode
BACKUP DATABASE Mastering
TO DISK = 'D:\Temp\SQLData\Mastering.bak'
WITH INIT
GO

/*
	Vamos delimitar o tamanho do log de transação...
*/
ALTER DATABASE Mastering
MODIFY FILE
	(Name = 'Mastering_Log',
	 Size = 10MB,
	 MAXSIZE = 30MB)
go

DBCC LOGINFO()

select COUNT(*)
from TabelaLog

-- Apagando 50.000 registros...
DELETE FROM TabelaLog
WHERE Codigo < 50000
go


-- ROLLBACK?
SELECT COUNT(*) FROM TabelaLog
go

-- Sim, espaço para compensating log record
dbcc loginfo()

select * FROM ::fn_dblog(null, null)



-- Encolhe
DBCC SHRINKFILE('Mastering_Log', 5)
go

-- OK?

-- Altera recovery model
ALTER DATABASE Mastering
SET RECOVERY SIMPLE
go

dbcc loginfo()

-- Encolhe
DBCC SHRINKFILE('Mastering_Log', 5)
go

-- OK?


-- Checagem
SELECT
	database_id,
	name,
	recovery_model_desc
FROM master.sys.databases
WHERE name = 'Mastering'
go

/*
	Agora que estamos com recovery model simple, as transações são truncadas on checkpoint
*/ 
DELETE FROM TabelaLog
WHERE Codigo < 50000
go




dbcc loginfo()

/*
	Resolvendo de forma eficiente
*/
DBCC SHRINKFILE('Mastering_Log', 5)
go

DELETE FROM TabelaLog WHERE Codigo < 10000
DELETE FROM TabelaLog WHERE Codigo < 20000
DELETE FROM TabelaLog WHERE Codigo < 30000
DELETE FROM TabelaLog WHERE Codigo < 40000
DELETE FROM TabelaLog WHERE Codigo < 50000
go
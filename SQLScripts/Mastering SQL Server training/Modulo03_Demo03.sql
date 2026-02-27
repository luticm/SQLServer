/****************************************************************************************
*****************************************************************************************
			
	***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 03 - Demo 03 - Database Snapshot
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE master
GO

IF (DB_ID('MasteringSnap') IS NOT NULL)
	DROP DATABASE MasteringSnap
GO

IF (DB_ID('MasteringSnap2') IS NOT NULL)
	DROP DATABASE MasteringSnap2
GO

IF (DB_ID('Mastering') IS NOT NULL)
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
  ON PRIMARY 
	(NAME = N'Mastering_Data01', 
	FILENAME = N'D:\Temp\SQLData\Mastering_Data01.mdf',
	SIZE = 10MB,
	MAXSIZE = 1GB,
	FILEGROWTH = 10MB)
  LOG ON 
  (NAME = N'Mastering_Log', 
	FILENAME = N'D:\Temp\SQLData\Mastering_log.ldf',
	SIZE = 10MB,
	MAXSIZE = 300MB,
	FILEGROWTH = 100MB)	
go

USE Mastering
go

IF (OBJECT_ID('TabelaGrande') IS NOT NULL)
	DROP TABLE TabelaGrande
go

CREATE TABLE TabelaGrande
(Codigo INT IDENTITY NOT NULL,
 Texto CHAR(8000) NOT NULL,
 Hora DATETIME2 NOT NULL DEFAULT SYSDATETIME())
go

DECLARE @I INT
SET @I = 0
WHILE (@I < 10)
BEGIN
	INSERT INTO TabelaGrande (Texto) VALUES ('Sr. Nimbus')
	SET @I = @I + 1
END
go

SELECT * FROM TabelaGrande
go

EXEC sp_helpfile
GO 

-- Cria o snapshot do banco de dados Mastering
CREATE DATABASE MasteringSnap
ON PRIMARY (NAME = 'Mastering_Data01', FILENAME = N'D:\Temp\SQLData\MasteringSnap_Data.mdf')
AS SNAPSHOT OF Mastering
go

-- Analisar file system

SELECT * FROM sys.databases
go

SELECT * FROM MasteringSnap.dbo.TabelaGrande
SELECT * FROM Mastering.dbo.TabelaGrande
go

UPDATE TabelaGrande
	SET Texto = 'Curso SQL Server 2014 Internals'
	WHERE Codigo = 1
go

-- Analisar file system
SELECT * FROM Mastering.dbo.TabelaGrande
SELECT * FROM MasteringSnap.dbo.TabelaGrande
go

UPDATE TabelaGrande
	SET Texto = 'MEU TESTE'
	WHERE Codigo = 1
go

-- Analisar file system
SELECT * FROM MasteringSnap.dbo.TabelaGrande
SELECT * FROM Mastering.dbo.TabelaGrande
go

DELETE FROM TabelaGrande WHERE Codigo = 2
go
	
INSERT INTO TabelaGrande (Texto) VALUES ('NOVO VALOR')
GO

SELECT * FROM MasteringSnap.dbo.TabelaGrande
SELECT * FROM Mastering.dbo.TabelaGrande
go

-- Cria o snapshot do banco de dados Mastering
CREATE DATABASE MasteringSnap2
ON PRIMARY (NAME = 'Mastering_Data01', FILENAME = N'D:\Temp\SQLData\MasteringSnap2_Data.mdf')
AS SNAPSHOT OF Mastering
go

-- Analisar file system
SELECT * FROM Mastering.dbo.TabelaGrande
SELECT * FROM MasteringSnap.dbo.TabelaGrande
SELECT * FROM MasteringSnap2.dbo.TabelaGrande
go

SELECT * FROM fn_virtualfilestats(DB_ID('Mastering'), 1)
SELECT * FROM fn_virtualfilestats(DB_ID('MasteringSnap'), 1)
SELECT * FROM fn_virtualfilestats(DB_ID('MasteringSnap2'), 1)
go

EXEC SP_SPACEUSED
GO

-- O que vai acontecer com o snapshot?
INSERT INTO TabelaGrande (Texto) VALUES ('Sr. Nimbus')
go 10000

-- Analisar file system
SELECT * FROM Mastering.dbo.TabelaGrande
SELECT * FROM MasteringSnap.dbo.TabelaGrande
SELECT * FROM MasteringSnap2.dbo.TabelaGrande
go

SELECT * FROM fn_virtualfilestats(DB_ID('Mastering'), 1)
SELECT * FROM fn_virtualfilestats(DB_ID('MasteringSnap'), 1)
SELECT * FROM fn_virtualfilestats(DB_ID('MasteringSnap2'), 1)
go

EXEC SP_SPACEUSED
GO

-- Analisar file system
SELECT * FROM Mastering.dbo.TabelaGrande
SELECT * FROM MasteringSnap.dbo.TabelaGrande
SELECT * FROM MasteringSnap2.dbo.TabelaGrande
go

USE master
go

-- Funciona?
RESTORE DATABASE Mastering
FROM DATABASE_SNAPSHOT = 'MasteringSnap'
go



drop database MasteringSnap2
go

RESTORE DATABASE Mastering
FROM DATABASE_SNAPSHOT = 'MasteringSnap'
go


SELECT * FROM msdb.dbo.restorehistory
-- Restore_Type -> R = Revert

EXEC sp_readerrorlog
GO

USE Mastering
go

SELECT * 
FROM TabelaGrande
ORDER BY Codigo
GO

-- Posso fazer isso?
USE master
DROP DATABASE Mastering
go

-- Limpeza
DROP DATABASE MasteringSnap
--DROP DATABASE Mastering
go


-- Um potencial problema...
USE Mastering
go

INSERT INTO TabelaGrande (Texto) VALUES ('Sr. Nimbus')
go 10000

drop database MasteringSnap3

CREATE DATABASE MasteringSnap3
ON PRIMARY (NAME = 'Mastering_Data01', FILENAME = N'D:\Temp\SQLData\MasteringSnap3_Data.mdf')
AS SNAPSHOT OF Mastering
go
CREATE DATABASE MasteringSnap2
ON PRIMARY (NAME = 'Mastering_Data01', FILENAME = N'D:\Temp\SQLData\MasteringSnap2_Data.mdf')
AS SNAPSHOT OF Mastering
go

SELECT * 
FROM sys.databases
WHERE name LIKE 'Mastering%'
go

DBCC DROPCLEANBUFFERS()
go

-- Mesma página de origem
SELECT * FROM Mastering.dbo.TabelaGrande
SELECT * FROM MasteringSnap3.dbo.TabelaGrande
SELECT * FROM MasteringSnap2.dbo.TabelaGrande
go

SELECT *
FROM sys.dm_os_buffer_descriptors
WHERE database_id IN (7,43,44)
ORDER BY page_id, database_id
go

/*
DATABASE SNAPSHOT E DATA CACHE TRASHING
http://luticm.blogspot.com.br/2011/07/artigo-o-caso-dos-snapshots-e-data.html
*/
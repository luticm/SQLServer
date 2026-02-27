/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	BloD: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 03 - Demo 01 - Banco de dados e FileGroups
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE master
GO

IF (DB_ID('Mastering') IS NOT NULL)
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
go

USE Mastering
go

SELECT * FROM sys.databases
SELECT * FROM sys.database_files
go

-- Múltiplos arquivos no filegroup, crescimento proporcional
USE master
GO

IF (DB_ID('Mastering') IS NOT NULL)
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
  ON PRIMARY 
	(NAME = N'Mastering_Data01', 
	FILENAME = N'D:\Temp\SQLData\Mastering_Data01.mdf',
	SIZE = 15MB,
	MAXSIZE = 1GB,
	FILEGROWTH = 10MB),	
  FILEGROUP fg01 DEFAULT
	(NAME = N'Mastering_Data02', 
	FILENAME = N'D:\Temp\SQLData\Mastering_Data02.ndf',
	SIZE = 10MB,
	MAXSIZE = 1GB,
	FILEGROWTH = 10MB),	
	(NAME = N'Mastering_Data03', 
	FILENAME = N'D:\Temp\SQLData\Mastering_Data03.ndf',
	SIZE = 10MB,
	MAXSIZE = 1GB,
	FILEGROWTH = 10MB)  
  LOG ON 
  (NAME = N'Mastering_Log', 
	FILENAME = N'D:\Temp\SQLLog\Mastering_log.ldf',
	SIZE = 10MB,
	MAXSIZE = 300MB,
	FILEGROWTH = 100MB)	
go

use Mastering
go

SELECT * FROM sys.databases
SELECT * FROM sys.database_files
SELECT * FROM sys.filegroups
go	

IF (OBJECT_ID('TabelaGrande') IS NOT NULL)
	DROP TABLE TabelaGrande
go

CREATE TABLE TabelaGrande
(Codigo INT IDENTITY NOT NULL,
 Texto CHAR(8000) NOT NULL,
 Hora DATETIME2 NOT NULL DEFAULT SYSDATETIME())
 go

-- Mostra crescimento dos arquivos...
DECLARE @I INT
SET @I = 0
WHILE (@I < 30000)
BEGIN
	INSERT INTO TabelaGrande (Texto) VALUES ('Sr. Nimbus')
	SET @I = @I + 1
END
GO

INSERT INTO TabelaGrande (Texto) VALUES ('Sr. Nimbus')
go 30000

select * from TabelaGrande ORDER BY CODIGO;

-- Crescimento proporcional


/*
	Crescimento proporcional
	Instant file initialization	
*/
USE master
GO
IF (DB_ID('Mastering') IS NOT NULL)
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
  ON PRIMARY 
	(NAME = N'Mastering_Data01', 
	FILENAME = N'D:\Temp\SQLData\Mastering_Data01.mdf',
	SIZE = 15MB,
	MAXSIZE = 1GB,
	FILEGROWTH = 10MB),	
  FILEGROUP fg01 DEFAULT
	(NAME = N'Mastering_Data02', 
	FILENAME = N'D:\Temp\SQLData\Mastering_Data02.ndf',
	SIZE = 10MB,
	MAXSIZE = 10GB,
	FILEGROWTH = 5GB),
	(NAME = N'Mastering_Data03', 
	FILENAME = N'D:\Temp\SQLData\Mastering_Data03.ndf',
	SIZE = 10MB,
	MAXSIZE = 10GB,
	FILEGROWTH = 5GB)  
  LOG ON 
  (NAME = N'Mastering_Log', 
	FILENAME = N'D:\Temp\SQLLog\Mastering_log.ldf',
	SIZE = 10MB,
	MAXSIZE = 10GB,
	FILEGROWTH = 5GB)	
go

USE Mastering
go

-- Analisar file info
DBCC TRACEON (3604)
DBCC TRACEON (3004) -- = Trace flag para informação de manipulação de arquivo
DBCC TRACESTATUS(-1)

IF (OBJECT_ID('TabelaGrande') IS NOT NULL)
	DROP TABLE TabelaGrande
go

CREATE TABLE TabelaGrande
(Codigo INT IDENTITY NOT NULL,
 Texto CHAR(8000) NOT NULL,
 Hora DATETIME2 NOT NULL DEFAULT SYSDATETIME())
 go

SELECT * FROM dbo.TabelagRANDE
go

DECLARE @I INT
SET @I = 0
WHILE (@I < 30000)
BEGIN
	INSERT INTO TabelaGrande (Texto) VALUES ('Sr. Nimbus')
	SET @I = @I + 1
END

select TOP 100 * FROM TabelaGrande
order by Hora

-- Intervalo entre 2 inserts maior que...
SELECT *
FROM TabelaGrande AS T1
INNER JOIN TabelaGrande AS T2
ON T1.Codigo = T2.Codigo - 1
WHERE DATEDIFF(S, T1.Hora, T2.Hora) > 10
go

SELECT *
FROM TabelaGrande AS T1
INNER JOIN TabelaGrande AS T2
ON T1.Codigo = T2.Codigo - 1
WHERE DATEDIFF(MS, T1.Hora, T2.Hora) > 600
go

BACKUP DATABASE Mastering
TO DISK = 'C:\Temp\BackupMastering.bak'
WITH INIT
go

xp_readerrorlog

-- AUTO TRUNCATE MODE OFF...

DECLARE @I INT
SET @I = 0
WHILE (@I < 30000)
BEGIN
	INSERT INTO TabelaGrande (Texto) VALUES ('Sr. Nimbus')
	SET @I = @I + 1
END
go

-- Pesquisar por zeroing em messages

-- Intervalo entre 2 inserts maior que...
SELECT *, DATEDIFF(SECOND, T1.Hora, T2.Hora)
FROM TabelaGrande AS T1
INNER JOIN TabelaGrande AS T2
ON T1.Codigo = T2.Codigo - 1
WHERE DATEDIFF(S, T1.Hora, T2.Hora) > 20
go
/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 04 - Demo 01 - Log buffer flush
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/
USE master
GO

-- DROP DATABASE MasteringSnap3
-- DROP DATABASE MasteringSnap2

IF (DB_ID('Mastering') IS NOT NULL)
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
GO

USE Mastering
go

IF (OBJECT_ID('TabelaLog') IS NOT NULL)
	DROP TABLE TabelaLog
go

CREATE TABLE TabelaLog
(Codigo INT IDENTITY NOT NULL,
 Texto CHAR(8000) NOT NULL,
 Hora DATETIME2 NOT NULL DEFAULT SYSDATETIME())
go

IF (OBJECT_ID('tempdb.dbo.ControleLogFlush') IS NOT NULL)
	DROP TABLE tempdb.dbo.[ControleLogFlush]
GO

CREATE TABLE tempdb.dbo.[ControleLogFlush](
	BD nvarchar(128) NULL,
	num_of_writes bigint NOT NULL,
	Momento VARCHAR(200) NOT NULL
)
GO

select * from tempdb.dbo.controlelogflush
go

SELECT *
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

-- Força um Log flush
CHECKPOINT
go

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'ANTES DE COMEÇAR - CHECKPOINT EXECUTADO' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

INSERT INTO TabelaLog (Texto) VALUES ('Antes do BEGIN TRANSACTION')
go

-- SELECT * FROM ::fn_dblog(NULL, NULL)

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'DEPOIS DO INSERT ISOLADO' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

BEGIN TRANSACTION

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'DEPOIS DO BEGIN TRANSACTION' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

INSERT INTO TabelaLog (Texto) VALUES ('DEPOIS DO BEGIN TRANSACTION')
go

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'DEPOIS DO INSERT NA TRANSAÇÃO' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'ANTES DO CHECKPOINT NA TRANSAÇÃO' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

CHECKPOINT

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'DEPOIS DO CHECKPOINT NA TRANSAÇÃO' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

INSERT INTO TabelaLog (Texto) VALUES ('DEPOIS DO CHECKPOINT')
go

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'DEPOIS DO CHECKPOINT E NOVO INSERT NA TRANSAÇÃO' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

INSERT INTO TabelaLog (Texto) VALUES ('ANTES DO COMMIT TRANSACTION')
go

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'ANTES DO COMMIT TRANSACTION' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

COMMIT TRANSACTION

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'DEPOIS DO COMMIT TRANSACTION' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

SELECT * FROM tempdb.dbo.ControleLogFlush



-- Brincadeira para casa...
-- ROLLBACK???


INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'ROLLBACK - Antes do Begin' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

BEGIN TRANSACTION

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'ROLLBACK - DEPOIS DO BEGIN TRANSACTION' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

INSERT INTO TabelaLog (Texto) VALUES ('DEPOIS DO BEGIN TRANSACTION')
go

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'ROLLBACK - DEPOIS DO INSERT' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

ROLLBACK

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'ROLLBACK - DEPOIS DO ROLLBACK' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

SELECT * FROM ::fn_dblog(NULL, NULL)
GO

CHECKPOINT
GO

INSERT INTO tempdb.dbo.ControleLogFlush
SELECT
	DB_NAME(database_id) as BD,
	num_of_writes,
	'ROLLBACK - DEPOIS DO CHECKPOINT' AS Momento
FROM sys.dm_io_virtual_file_stats(DB_ID(), 2)
go

SELECT * FROM tempdb.dbo.ControleLogFlush
GO

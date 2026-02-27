/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 03 - Demo 02 - Contained Databases
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
CONTAINMENT = PARTIAL;
-- CONTAINMENT = NONE regular database
-- FULL?
GO

sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO

CREATE DATABASE Mastering 
CONTAINMENT = PARTIAL;
GO

SELECT 
	containment,
	containment_desc,
	user_access,
	user_access_desc,
	* 
FROM sys.databases
go

USE Mastering
go

-- Database users vs Login Users
CREATE USER Luticm WITH PASSWORD = 'P@ssw0rd';
GO

-- Adicionar uma conta usando SSMS
-- Windows Auth

SELECT * 
FROM sys.server_principals
GO

SELECT 
	authentication_type,
	authentication_type_desc,
	* 
FROM sys.database_principals
go

SELECT *
FROM sys.dm_db_uncontained_entities 
GO

CREATE PROCEDURE P1
AS 
	SELECT COUNT(*)
	FROM AdventureWorks2012.Sales.SalesOrderHeader
go

SELECT *
FROM sys.dm_db_uncontained_entities 
GO

IF OBJECT_ID('dbo.TabelaContida', 'U') IS NOT NULL
	DROP TABLE dbo.TabelaContida
GO

CREATE TABLE dbo.TabelaContida (
	ID INT IDENTITY NOT NULL PRIMARY KEY
	, Nome VARCHAR(100) NOT NULL DEFAULT ('Sr. Nimbus')
	, DataRegistro DATETIME2 NOT NULL DEFAULT(SYSDATETIME())
)
GO

INSERT INTO dbo.TabelaContida DEFAULT VALUES
GO

CREATE PROCEDURE P2
AS 
	SELECT COUNT(*)
	FROM dbo.TabelaContida
go

SELECT *
FROM sys.dm_db_uncontained_entities 
GO

CREATE PROCEDURE P3
AS 
	SELECT COUNT(*)
	FROM sys.objects
go



USE master
GO

IF (DB_ID('Mastering') IS NOT NULL)
	DROP DATABASE Mastering
GO
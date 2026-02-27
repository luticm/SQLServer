/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 04 - Demo 06 - Delayed Durability (HOMEWORK!)
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/


USE Master
go

ALTER DATABASE Mastering
SET SINGLE_USER with rollback immediate

-- DROP DATABASE Mastering

CREATE DATABASE Mastering
ON
PRIMARY (
  NAME = 'Mastering_Data',
  FILENAME = 'C:\temp\Mastering_Data.mdf',
  SIZE = 250 MB
)
LOG ON
(
  NAME = 'Mastering_Log',
  FILENAME = 'F:\temp\Mastering.ldf',
  SIZE = 200 MB
) 

SELECT delayed_durability, delayed_durability_desc, * 
FROM SYS.DATABASES WHERE NAME = 'Mastering'
go

USE Mastering
go

IF OBJECT_ID('dbo.DelayedDurability', 'U') IS NOT NULL
	DROP TABLE dbo.DelayedDurability
GO

CREATE TABLE dbo.DelayedDurability (
	ID INT IDENTITY NOT NULL
    , Texto CHAR(100) NOT NULL DEFAULT ('SQL Server 2014')  
)
GO

INSERT INTO dbo.DelayedDurability DEFAULT VALUES;

SELECT *
FROM dbo.DelayedDurability;

CHECKPOINT

/*
	1 threads
	1000 iterations
	INSERT INTO dbo.DelayedDurability DEFAULT VALUES;

	~ 4 segundos

	--> Recriar a tabela

	SQLQueryStress + IOMeter
	4 threads, 30 segundos, 4K 50% read
	
	~ 20 segundos
*/

ALTER DATABASE Mastering
SET DELAYED_DURABILITY = FORCED
GO

SELECT delayed_durability, delayed_durability_desc, * 
FROM SYS.DATABASES WHERE NAME = 'Mastering'
go

/*
	--> Recriar a tabela

	SQLQueryStress + IOMeter
	4 threads, 30 segundos, 4K 50% read
	
	~ 4 ou 5 segundos
*/

SELECT *
FROM dbo.DelayedDurability;

EXEC sys.sp_flush_log;
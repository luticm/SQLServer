/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 06 - Demo 05 - DBCC SHRINKFILE
	Descrição: COPIADO DESCARADAMENTE DO POST DO PAUL RANDAL
		FROM: http://www.sqlskills.com/blogs/paul/post/Why-you-should-not-shrink-your-data-files.aspx
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE MASTER
GO

IF EXISTS (SELECT * FROM SYSDATABASES WHERE [Name] = 'Mastering')
BEGIN
	DROP DATABASE Mastering
END
GO

CREATE DATABASE Mastering
GO

USE Mastering
GO

-- Create the 10MB filler table at the 'front' of the data file
CREATE TABLE FillerTable (c1 INT IDENTITY,  c2 CHAR (8000) DEFAULT 'filler')
GO 

-- Fill up the filler table
INSERT INTO FillerTable DEFAULT VALUES
GO 1280 

-- Create the production table, which will be 'after' the filler table in the data file
CREATE TABLE ProdTable (c1 INT IDENTITY,  c2 CHAR (8000) DEFAULT 'production')
CREATE CLUSTERED INDEX prod_cl ON ProdTable (c1)
GO 

INSERT INTO ProdTable DEFAULT VALUES
GO 1280 

-- check the fragmentation of the production table
SELECT [avg_fragmentation_in_percent], * FROM sys.dm_db_index_physical_stats (
    DB_ID ('Mastering'), OBJECT_ID ('ProdTable'), 1, NULL, 'LIMITED')
GO 

-- drop the filler table, creating 10MB of free space at the 'front' of the data file
DROP TABLE FillerTable
GO 

-- shrink the database
DBCC SHRINKDATABASE (Mastering)
GO 

-- check the index fragmentation again
SELECT [avg_fragmentation_in_percent] FROM sys.dm_db_index_physical_stats (
    DB_ID ('Mastering'), OBJECT_ID ('ProdTable'), 1, NULL, 'LIMITED')
GO

SELECT * FROM fn_dblog(NULL, NULL)

ALTER INDEX prod_cl
ON ProdTable REORGANIZE
GO

SELECT *
FROM SYS.indexES
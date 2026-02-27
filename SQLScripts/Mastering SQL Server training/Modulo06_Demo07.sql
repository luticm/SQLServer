/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL Server - Administração e Monitoramento		   		  ***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 11 - Demo 02 - ColumnStore Indexes Internals
	Descrição: 
		
	* Copyright (C) 2015 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE master
GO

IF (DB_ID('CSInternals') IS NOT NULL)
	DROP DATABASE CSInternals
GO

CREATE DATABASE CSInternals
  ON PRIMARY 
	(NAME = N'CSInternals_Data01', 
	FILENAME = N'D:\Temp\SQLData\CSInternals_Data01.mdf',
	SIZE = 15MB,
	MAXSIZE = 1GB,
	FILEGROWTH = 10MB),	
  FILEGROUP fg01 DEFAULT
	(NAME = N'CSInternals_Data02', 
	FILENAME = N'D:\Temp\SQLData\CSInternals_Data02.ndf',
	SIZE = 10GB,
	MAXSIZE = 100GB,
	FILEGROWTH = 1GB)
  LOG ON 
  (NAME = N'CSInternals_Log', 
	FILENAME = N'D:\Temp\SQLLog\CSInternals_log.ldf',
	SIZE = 1GB,
	MAXSIZE = 30GB,
	FILEGROWTH = 1GB)	
GO

USE CSInternals
GO

IF (OBJECT_ID('dbo.TabelaFato') IS NOT NULL)
	DROP TABLE dbo.TabelaFato
go

CREATE TABLE dbo.TabelaFato
(Codigo INT IDENTITY NOT NULL PRIMARY KEY,
 Nome VARCHAR(100) NOT NULL,
 Ref01 INT NULL,
 Ref02 INT NULL,
 Ref03 INT NULL,
 Valor01 DECIMAL(10,2) NULL,
 Valor02 DECIMAL(10,2) NULL,
 Valor03 DECIMAL(10,2) NULL,
 DataEvento DATETIME2 NULL,
 DataHora DATETIME2 NOT NULL DEFAULT SYSDATETIME())
GO

/*
	SELECT TOP 100 *
	FROM sys.dm_xe_map_values AS V
	CROSS JOIN sys.dm_xe_objects AS O

	SELECT * FROM dbo.TabelaFato
*/

-- Insert de 3MI+ registros
INSERT INTO	dbo.TabelaFato (Nome, Ref01, Ref02, Ref03, Valor01, Valor02, Valor03, DataEvento)
SELECT TOP 3050000
	LEFT(O.name + '_' + V.name, 100),
	ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Ref01,
	ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Ref02,
	ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Ref03,
	ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Valor01,
	ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Valor02,
	ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Valor03,
	CONVERT(DATETIME, GETDATE() - (CheckSUM(NEWID()) / 1000000.0)) AS OrderDate1
FROM sys.dm_xe_map_values AS V
CROSS JOIN sys.dm_xe_objects AS O

SELECT COUNT(*) FROM dbo.TabelaFato;
SELECT TOP 1000 * FROM dbo.TabelaFato;

-- Criando um índice NCCS
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_NCLC_tabelafato
ON dbo.TabelaFato (Codigo, Nome, Ref01, Ref02, Ref03, Valor01, Valor02, Valor03, DataEvento, DataHora)
GO

-- Comparando o tamanho final dos objetos
SELECT au.used_pages, *
FROM sys.partitions AS P
INNER JOIN sys.system_internals_allocation_units AS AU
ON P.partition_id = AU.container_id
WHERE P.object_id = object_id('dbo.TabelaFato')
GO

/*
	Used pages
3 - 9929
1 - 42705
*/

EXEC SP_HELPINDEX2 'dbo.TabelaFato'

ALTER INDEX [PK__TabelaFa__06370DAD7697FEBE] ON dbo.TabelaFato
REBUILD
WITH (DATA_COMPRESSION = PAGE);

SELECT au.used_pages, *
FROM sys.partitions AS P
INNER JOIN sys.system_internals_allocation_units AS AU
ON P.partition_id = AU.container_id
WHERE P.object_id = object_id('dbo.TabelaFato')
GO

/*
	Used pages
29925
9929
*/

-- Tamanho em MB: 75.929687
SELECT (9719 * 8) / 1024.0

/*
	1a analise - row_group_id, total_rows, size_in_bytes
*/
SELECT row_group_id, total_rows, size_in_bytes, SRG.*
FROM sys.column_store_row_groups AS SRG
GO

-- 70 MB
SELECT (SUM(SRG.size_in_bytes) / 1024.0) / 1024.0
FROM sys.column_store_row_groups AS SRG
GO

-- Analisar coluna por coluna
SELECT * FROM sys.column_store_row_groups
SELECT * FROM sys.column_store_segments
SELECT * FROM sys.column_store_dictionaries

SELECT TOP 1000 * FROM dbo.TabelaFato;

/*
	1 - Value based encoding
	2 - Dictionary encoding non-strings
	3 - Dictionary encoding strings
	4 - No encoding

	Dictionary type:

	1 – Hash dictionary containing int values 
	2 – Not used
	3 – Hash dictionary containing string values
	4 – Hash dictionary containing float values 
*/

-- substituir partition_id
SELECT *
FROM sys.partitions AS P
INNER JOIN sys.system_internals_allocation_units AS AU
ON P.partition_id = AU.container_id
WHERE P.partition_id = 72057594040614912
GO

-- 0x110000000300


DBCC TRACEON(3604)
DBCC PAGE (5, 3, 21, 3)
DBCC PAGE (5, 3, 21, 2)

-- Nadinha??? Look closer...

-- 0101
DBCC PAGE (5, 3, 258, 2)




select top 1 seg.hobt_id, DB_ID() 
from sys.column_store_segments seg
inner join sys.partitions as p 
	ON seg.partition_id = p.partition_id
where OBJECT_id = OBJECT_ID('dbo.TabelaFato');
go


/*
DBCC CSIndex (
    {'dbname' | db_id}, 
    rowsetid, -- HoBT or PartitionID from sys.column_store_segments
    columnid, -- column_id from sys.column_store_segments
    rowgroupid, -- segment_id from sys.column_store_segments
    object_type, -- 1 (Segment), 2 (Dictionary),
    print_option -- {0 or 1 or 2}; No idea what is the difference between those values.
	)
*/

SELECT * FROM sys.column_store_row_groups
SELECT * FROM sys.column_store_segments
SELECT * FROM sys.column_store_dictionaries

DBCC TRACEON(3604)
-- Segmento
DBCC CSINDEX(5, 72057594040614912, 2, 0, 1, 0)
-- Dicionário (extract dos valores + huffman)
DBCC CSINDEX(5, 72057594040614912, 2, 0, 2, 0)






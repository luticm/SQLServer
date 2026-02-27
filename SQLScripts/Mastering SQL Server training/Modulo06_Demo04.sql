/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Demo 04 - Fragmentação no SQL Server
	Descrição: 

		
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

/*
	Cria a tabela que será analisada. Para que as análises sejam consistentes a
	tabela somente deve estar em 1 arquivo.
*/
IF EXISTS(SELECT * FROM sysObjects WHERE [Name] = 'Fragmentation' AND XType = 'U')
BEGIN
	DROP TABLE Fragmentation
END

CREATE TABLE Fragmentation
(
	PKIdentity INT NOT NULL IDENTITY CONSTRAINT PK_PKIdentity PRIMARY KEY,
	Name VARCHAR(100)
)
GO

/*
	Gera uma massa de dados para a tabela
*/
Declare @Contador INT
SET @Contador = 0

WHILE @Contador < 10000
BEGIN
	INSERT INTO Fragmentation VALUES (Replicate('L', 100))
	SET @Contador = @Contador + 1
END
GO

SET STATISTICS IO ON
SELECT * FROM Fragmentation
GO

/*
	Verifica a fragmentação da tabela. Neste momento a fragmentação deve ser muito baixa
*/
DBCC SHOWCONTIG (Fragmentation, 1)
-- DBCC SHOWCONTIG (Fragmentation, 1) WITH tableresults - Forwarded records
go
/*
<Cole aqui o resultado>

DBCC SHOWCONTIG scanning 'Fragmentation' table...
Table: 'Fragmentation' (245575913); index ID: 1, database ID: 8
TABLE level scan performed.
- Pages Scanned................................: 145
- Extents Scanned..............................: 20
- Extent Switches..............................: 19
- Avg. Pages per Extent........................: 7.3
- Scan Density [Best Count:Actual Count].......: 95.00% [19:20]
- Logical Scan Fragmentation ..................: 1.38%
- Extent Scan Fragmentation ...................: 0.00%
- Avg. Bytes Free per Page.....................: 27.0
- Avg. Page Density (full).....................: 99.67%
DBCC execution completed. If DBCC printed error messages, contact your system administrator.

*/

SELECT DB_ID()
go

SELECT * 
FROM sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('Fragmentation'), NULL, NULL)
WHERE object_id > 10000
go

/*
Notar os records counts para o nível 1 (145) e o número de páginas no nível 0.
*/
SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Fragmentation'), null, null, 'DETAILED' )
WHERE object_id > 10000
go
-- Fragment: A fragment is made up of physically consecutive leaf pages in the same file for an allocation unit


/*
	Cria uma fragmentação excluindo 1/3 das páginas
*/
DELETE FROM Fragmentation
WHERE (PKIdentity % 3) = 0
go

SET STATISTICS IO ON

SELECT * FROM Fragmentation
GO

-- O que deve mudar??
DBCC SHOWCONTIG (Fragmentation, 1)
GO

/*
DBCC SHOWCONTIG scanning 'Fragmentation' table...
Table: 'Fragmentation' (5575058); index ID: 1, database ID: 44
TABLE level scan performed.
- Pages Scanned................................: 145
- Extents Scanned..............................: 22
- Extent Switches..............................: 21
- Avg. Pages per Extent........................: 6.6
- Scan Density [Best Count:Actual Count].......: 86.36% [19:22]
- Logical Scan Fragmentation ..................: 3.45%
- Extent Scan Fragmentation ...................: 13.64%
- Avg. Bytes Free per Page.....................: 2716.4
- Avg. Page Density (full).....................: 66.44%
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
*/
--

SELECT * 
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Fragmentation'), null, null, 'DETAILED' )
WHERE object_id > 10000
go

-- O que o LIMITED faz? Varre o nível não folha antes do índice
SELECT * 
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Fragmentation'), null, null, 'LIMITED' )
WHERE object_id > 10000
go


-- Assim que fazíamos antigamente, mas essa funcionalidade será descontinuada
-- DBCC INDEXDEFRAG (0, 'Fragmentation', 1)

ALTER INDEX PK_PKIdentity
ON Fragmentation REORGANIZE
GO

DBCC SHOWCONTIG (Fragmentation, 1)
GO

/*
DBCC SHOWCONTIG scanning 'Fragmentation' table...
Table: 'Fragmentation' (2105058535); index ID: 1, database ID: 12
TABLE level scan performed.
- Pages Scanned................................: 97
- Extents Scanned..............................: 14
- Extent Switches..............................: 13
- Avg. Pages per Extent........................: 6.9
- Scan Density [Best Count:Actual Count].......: 92.86% [13:14]
- Logical Scan Fragmentation ..................: 4.12%
- Extent Scan Fragmentation ...................: 35.71%
- Avg. Bytes Free per Page.....................: 54.4
- Avg. Page Density (full).....................: 99.33%
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
*/

SELECT * 
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Fragmentation'), null, null, 'DETAILED' )
WHERE object_id > 10000
go

SELECT * FROM Fragmentation
GO

-- O drop existing garante que será uma operação atômica, porém índice não fica disponível
CREATE UNIQUE CLUSTERED INDEX PK_PKIdentity
ON Fragmentation (PKIdentity)
WITH DROP_EXISTING
GO

DBCC SHOWCONTIG (Fragmentation, 1)
GO
/*
DBCC SHOWCONTIG scanning 'Fragmentation' table...
Table: 'Fragmentation' (5575058); index ID: 1, database ID: 44
TABLE level scan performed.
- Pages Scanned................................: 97
- Extents Scanned..............................: 13
- Extent Switches..............................: 12
- Avg. Pages per Extent........................: 7.5
- Scan Density [Best Count:Actual Count].......: 100.00% [13:13]
- Logical Scan Fragmentation ..................: 1.03%
- Extent Scan Fragmentation ...................: 15.38%
- Avg. Bytes Free per Page.....................: 54.4
- Avg. Page Density (full).....................: 99.33%
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
*/

SELECT * 
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Fragmentation'), null, null, 'DETAILED' )
WHERE object_id > 10000
go

-- Old Style
-- DBCC DBREINDEX('Fragmentation', 'PK_PKIdentity', 0) 

-- Pode fazer o rebuild online, usando o recurso de row versioning
-- Colocamos o fillfactor para verificar preenchimento da página
ALTER INDEX PK_PKIdentity
ON Fragmentation 
REBUILD WITH (ONLINE = OFF, FILLFACTOR = 80)
GO

DBCC SHOWCONTIG (Fragmentation, 1)
GO
/*
DBCC SHOWCONTIG scanning 'Fragmentation' table...
Table: 'Fragmentation' (2105058535); index ID: 1, database ID: 5
TABLE level scan performed.
- Pages Scanned................................: 120
- Extents Scanned..............................: 15
- Extent Switches..............................: 14
- Avg. Pages per Extent........................: 8.0
- Scan Density [Best Count:Actual Count].......: 100.00% [15:15]
- Logical Scan Fragmentation ..................: 0.00%
- Extent Scan Fragmentation ...................: 6.67%
- Avg. Bytes Free per Page.....................: 1595.7
- Avg. Page Density (full).....................: 80.29%
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
*/

SELECT * 
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Fragmentation'), null, null, 'DETAILED' )
WHERE object_id > 10000
GO

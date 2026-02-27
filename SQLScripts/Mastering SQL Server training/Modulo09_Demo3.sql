/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 09 - Compressão de dados
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/
--ALTER DATABASE Mastering
--SET SINGLE_USER WITH ROLLBACK IMMEDIATE

-- drop database Mastering
CREATE DATABASE Mastering
go
USE Mastering
go

-- DROP TABLE CompressadoDados
CREATE TABLE CompressadoDados
(Codigo BIGINT IDENTITY PRIMARY KEY NOT NULL,
 Nome VARCHAR(100) NOT NULL,
 Idade BIGINT NOT NULL,
 SeloTempo ROWVERSION NOT NULL)
GO

DECLARE @I INT
SET @I = 1
WHILE (@I < 20000)
BEGIN
	INSERT INTO CompressadoDados (Nome, Idade) VALUES 
		(CAST(NEWID() AS VARCHAR(40)) + CAST(NEWID() AS VARCHAR(40)), @I % 100)
	SET @I = @I + 1
END

SELECT TOP 100 *
FROM CompressadoDados

SELECT p.*, AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('CompressadoDados')
go
-- 0x260100000100	0x280100000100	0x270100000100

ALTER TABLE CompressadoDados 
REBUILD WITH (DATA_COMPRESSION = ROW);
GO

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('CompressadoDados')
go
-- 1	72057594039894016	1	IN_ROW_DATA	72057594038845440	1	233	220	218	0xC00100000100	0x000200000100	0x730000000100

ALTER TABLE CompressadoDados 
REBUILD WITH (DATA_COMPRESSION = NONE);
GO

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('CompressadoDados')
go

-- Vamos ganhar mais?
ALTER TABLE CompressadoDados 
REBUILD WITH (DATA_COMPRESSION = PAGE);
GO

SELECT TOP 100 *
FROM CompressadoDados
go

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('CompressadoDados')
go
-- 0x100300000100	0x300300000100	0x180100000100

ALTER TABLE CompressadoDados 
REBUILD WITH (DATA_COMPRESSION = NONE);
GO

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('CompressadoDados')
go

-- 0x200300000100	0x400300000100	0x280100000100

SELECT TOP 10 * FROM CompressadoDados 
-- ADBB2F45-579F-47CA-9E12-3C3ED4805AE4200EB398-37AF-4EEF-AF33-24F9CDB39425


-- Analisando...
DBCC TRACEON(3604)
DBCC PAGE(Mastering, 1, 800, 1)
GO
--   m_slotCnt = 74 

/*
Slot 0, Offset 0x60, Length 107, DumpStyle BYTE

Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
Record Size = 107                   
Memory Dump @0x0000000012B5A060

0000000000000000:   30001c00 01000000 00000000 01000000 00000000  0...................
0000000000000014:   00000000 000007d1 04000001 006b0041 44424232  .......Ñ.....k.ADBB2
0000000000000028:   4634352d 35373946 2d343743 412d3945 31322d33  F45-579F-47CA-9E12-3
000000000000003C:   43334544 34383035 41453432 30304542 3339382d  C3ED4805AE4200EB398-
0000000000000050:   33374146 2d344545 462d4146 33332d32 34463943  37AF-4EEF-AF33-24F9C
0000000000000064:   44423339 343235                               DB39425                              E573096                              EBEEEE1
*/

ALTER TABLE CompressadoDados 
REBUILD WITH (DATA_COMPRESSION = ROW);
GO

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('CompressadoDados')
go

-- 0xE80100000100	0x080200000100	0x190100000100

-- Analisando
DBCC PAGE(Mastering, 1, 512, 1)
GO
-- m_slotCnt = 93 

/*
DATA:


Slot 0, Offset 0x60, Length 85, DumpStyle BYTE

Record Type = (COMPRESSED) PRIMARY_RECORD                                 Record attributes =  LONG DATA REGION
Record size = 85                     
CD Array

CD array entry = Column 1 (cluster 0, CD array offset 0): 0x02 (ONE_BYTE_SHORT)
CD array entry = Column 2 (cluster 0, CD array offset 0): 0x0a (LONG)     
CD array entry = Column 3 (cluster 0, CD array offset 1): 0x02 (ONE_BYTE_SHORT)
CD array entry = Column 4 (cluster 0, CD array offset 1): 0x03 (TWO_BYTE_SHORT)

Record Memory Dump

0000000013AAA060:   2104a232 818107d1 01010048 00333332 †!.¢2...Ñ...H.332 
0000000013AAA070:   39393530 422d3846 30372d34 3546372d †9950B-8F07-45F7- 
0000000013AAA080:   41354238 2d363934 39363542 38413241 †A5B8-694965B8A2A 
0000000013AAA090:   34433035 34463033 412d4443 34382d34 †4C054F03A-DC48-4 
0000000013AAA0A0:   3042352d 42383335 2d333235 39454434 †0B5-B835-3259ED4 
0000000013AAA0B0:   41363034 45††††††††††††††††††††††††††A604E   
*/

DBCC PAGE(Mastering, 1, 513, 3)
GO

ALTER TABLE CompressadoDados 
REBUILD WITH (DATA_COMPRESSION = NONE);
GO

exec sp_estimate_data_compression_savings 'dbo', 'CompressadoDados', null, null, row
exec sp_estimate_data_compression_savings 'dbo', 'CompressadoDados', null, null, page


/*
	Criar tabela de nomes...
*/

-- DROP TABLE PESSOA
CREATE TABLE Pessoa
(Codigo BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 Nome VARCHAR(1000) NOT NULL,
 Idade BIGINT NULL,
 SeloTempo ROWVERSION NOT NULL)
go

-- Primeiro nome
INSERT INTO Pessoa (Nome, Idade)
SELECT L.LName + ' ' + F.Fname + ' ' + F.Fname + ' ' + L.LName, 0
FROM tempdb.dbo.FirstName AS F
CROSS JOIN tempdb.dbo.LastName AS L
go

UPDATE Pessoa 
SET Idade = codigo % 100
go

SELECT TOP 100 * FROM Pessoa
go

exec sp_estimate_data_compression_savings 'dbo', 'Pessoa', null, null, row
exec sp_estimate_data_compression_savings 'dbo', 'Pessoa', null, null, page
/*
object_name schema_name index_id    partition_number size_with_current_compression_setting(KB) size_with_requested_compression_setting(KB) sample_size_with_current_compression_setting(KB) sample_size_with_requested_compression_setting(KB)
Pessoa	dbo	1	1	3768	2776	3320	2448
Pessoa	dbo	1	1	3768	2768	3320	2440
*/

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go
-- 1	72057594040942592	1	IN_ROW_DATA	72057594039959552	1	473	471	469	0xA50000000100	0xA70000000100	0xA60000000100

DBCC TRACEON(3604)
DBCC PAGE(Mastering, 1, 305, 1)

ALTER TABLE Pessoa 
REBUILD WITH (DATA_COMPRESSION = PAGE);
GO

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go
-- 0x180400000100

DBCC PAGE(Mastering, 1, 1192, 1)
DBCC PAGE(Mastering, 1, 1080, 2)
GO

/*
Âncora - Silva Maria

00000000144DA065:   2104a040 01140101 01002100 53696c76 61204d61  !. @......!.Silva Ma
00000000144DA079:   72696120 4c696e61 204d6172 6961204c 696e6120  ria Lina Maria Lina 
00000000144DA08D:   53696c76 61                                   Silva  
Anchor record entry = Column  1, <NULL>                                  
Anchor record entry = Column  2, offset  12 length 33 @ 0x00000000144DA071
Anchor record entry = Column  3, <NULL>                                  
Anchor record entry = Column  4, offset   4 length  3 @ 0x00000000144DA069

Silva Carolina

00000000144DA1DB:   2104a342 998aa601 13c00101 00180006 4361726f  !.£B.¦..À......Caro
00000000144DA1EF:   6c696e61 20436172 6f6c696e 61205369 6c7661    lina Carolina Silva

"Silva " = 0006

Silva Marcos

00000000144DA202:   2104a342 998ba701 13c10101 00110009 636f7320  !.£B.§..Á.....	cos 
00000000144DA216:   4d617263 6f732053 696c7661                    Marcos Silva

"Silva Mar" = 0009
*/



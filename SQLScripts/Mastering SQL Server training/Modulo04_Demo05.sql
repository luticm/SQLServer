/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 04 - Demo 05 - LSN, fn_dblog e o cabeçalho das páginas	
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
GO

USE Mastering
go

IF (OBJECT_ID('TabelaLog') IS NOT NULL)
	DROP TABLE TabelaLog
go

CREATE TABLE TabelaLog
(Codigo INT IDENTITY NOT NULL,
 Texto CHAR(8000) NOT NULL,
 Hora DATETIME2 NOT NULL DEFAULT (SYSDATETIME())
 )
 GO

CHECKPOINT

-- Duas maneiras, ambas não documentadas
DBCC LOGINFO()

DBCC LOG(0,0)
SELECT * FROM ::fn_dblog(null, null)
go

SELECT * FROM TabelaLog

INSERT INTO TabelaLog (Texto) VALUES ('Sr. Nimbus')

SELECT * FROM ::fn_dblog(null, null)
go

-- Mostro parte inativa do log de transação
DBCC TRACEON(2537)

-- Qual a página? 0001:00000126
-- 00000021:0000007d:0018	LOP_INSERT_ROWS	LCX_HEAP

SELECT * 
FROM sys.sysindexes
WHERE id = OBJECT_ID('TabelaLog')
-- Qual é object id? 245575913


SELECT DB_ID()
-- 0x990000000100
DBCC TRACEON(3604)
DBCC PAGE(Mastering, 1, 294, 3)

SELECT * FROM dbo.TabelaLog
SELECT * FROM sys.dm_os_buffer_descriptors WHERE page_id = 294

CHECKPOINT

UPDATE TabelaLog 
	SET Texto = 'Teste flush data cache'
WHERE Codigo = 1

SELECT * FROM ::fn_dblog(null, null)
go

-- 00000024:0000009c:0002	LOP_MODIFY_ROW	LCX_HEAP

SHUTDOWN WITH NOWAIT

sp_readerrorlog

DBCC TRACEON(3604)
DBCC PAGE(Mastering, 1, 294, 3)


-- Qual o m_lsn?
-- m_lsn = (36:156:2)
-- Hora da mágica...


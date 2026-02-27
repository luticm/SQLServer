/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 10 - Filestream e FileTable
	Descrição: Analisa as características de cada nível de isolamento
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE Master
go

-- 1) Configura SQL Server para acesso FileStream (1 = T-SQL, 2 = T-SQL + Win32)
exec sp_configure 'filestream access level', 2
RECONFIGURE

-- 2) Cria banco de dados com Filestream e tabela que utiliza recurso
IF EXISTS (SELECT * FROM sys.databases WHERE name = N'FileStreamDB')
  DROP DATABASE FileStreamDB
GO

CREATE DATABASE FileStreamDB ON PRIMARY
  ( NAME = FileStreamDB_data, 
    FILENAME = N'C:\Temp\Filestream\DBs\FileStreamDB_data.mdf',
    SIZE = 15MB,
    MAXSIZE = 50MB, 
    FILEGROWTH = 15%),
FILEGROUP FileStreamGroup1 CONTAINS FILESTREAM
  ( NAME = FileStreamDB_CVs, 
    FILENAME = N'C:\Temp\Filestream\DBs\CVs')
LOG ON 
  ( NAME = 'FileStreamDB_log', 
    FILENAME = N'C:\Temp\Filestream\DBs\FileStreamDB_log.ldf',
    SIZE = 5MB, 
    MAXSIZE = 25MB, 
    FILEGROWTH = 5MB);
GO

-- ! Analisar estrutura criada no file system

USE FileStreamDB
go

IF EXISTS (SELECT * FROM sys.objects WHERE name = N'CurriculumVitae')
  DROP TABLE CurriculumVitae
GO
CREATE TABLE CurriculumVitae
(Codigo uniqueidentifier NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
 Nome VARCHAR(255) NOT NULL,
 CV VARBINARY(MAX) FILESTREAM)
GO

-- ! Analisar estrutura criada no file system

/*
	3) Inserindo e recuperando registros. E porque ROWGUIDCOL?
*/
INSERT INTO CurriculumVitae (Nome, CV) VALUES ('Luciano Caixeta Moreira', 
	CAST('Procurando por uma demonstração interessante...' AS VARBINARY(MAX)))
INSERT INTO CurriculumVitae (Nome, CV) VALUES ('Fulano de Tal', 
	CAST(REPLICATE('Procurando por uma demonstração interessante...', 100) AS VARBINARY(MAX)))
GO

SELECT Codigo, Nome, CAST(CV as varchar(MAX)) FROM CurriculumVitae
go

-- ! Analisar estrutura criada no file system
SELECT $ROWGUID FROM CurriculumVitae

/*
	4) Gerenciamento de transações e GET_FILESTREAM_TRANSACTION_CONTEXT
*/
SELECT GET_FILESTREAM_TRANSACTION_CONTEXT()
GO

BEGIN TRANSACTION

	UPDATE CurriculumVitae
	SET CV = CAST('Sabe demonstrar a funcionalidade de Filestream storage!' AS VARBINARY(MAX))
	WHERE Nome = 'Luciano Caixeta Moreira'

	SELECT @@TRANCOUNT

	SELECT GET_FILESTREAM_TRANSACTION_CONTEXT()
	-- ! Analisar estrutura criada no file system

	SELECT Codigo, Nome, CAST(CV as varchar(MAX)) FROM CurriculumVitae


ROLLBACK
-- COMMIT TRANSACTION

SELECT Codigo, Nome, CAST(CV as varchar(MAX)) FROM CurriculumVitae
go

/*
	5) Função importante quando estamos trabalhando com FS
*/
SELECT Codigo, Nome, CAST(CV as varchar(MAX)) AS CV, 
	CV.PathName() AS Arquivo 
FROM CurriculumVitae AS C

checkpoint


/*
	6) Backup/Restore de FileStream
*/
BACKUP DATABASE FileStreamDB
TO DISK = 'C:\temp\FileStreamDB.BAK'
WITH INIT
go

USE master
go

DROP DATABASE FileStreamDB
go

RESTORE DATABASE FileStreamDB
FROM DISK = 'C:\temp\FileStreamDB.BAK'
go

use FileStreamDB
go


/*
select DB_ID()

SELECT * FROM SYS.sysindexes
WHERE ID = OBJECT_ID('cURRICULUMVitae')

DBCC TRACEON(3604)
DBCC PAGE (8, 1, 114, 3)
*/

-- Tudo OK?
SELECT Codigo, Nome, CAST(CV as varchar(MAX)) AS CV, CV.PathName() AS Arquivo 
FROM CurriculumVitae AS C
WHERE codigo = '0A0CB01B-A27F-E311-AEED-9B138DAEBFC8'


SELECT Codigo, Nome
FROM CurriculumVitae AS C
go


USE Master
go

IF EXISTS (SELECT * FROM sys.databases WHERE name = N'FileTableDB')
  DROP DATABASE FileTableDB
GO

CREATE DATABASE FileTableDB ON PRIMARY
  ( NAME = FileStreamDB_data, 
    FILENAME = N'C:\Temp\FileTable\FileStreamDB_data.mdf',
    SIZE = 15MB,
    MAXSIZE = 50MB, 
    FILEGROWTH = 15%),
FILEGROUP FileStreamGroup1 CONTAINS FILESTREAM
  ( NAME = FileStreamDB_CVs, 
    FILENAME = N'C:\Temp\FileTable\Docs\')
LOG ON 
  ( NAME = 'FileStreamDB_log', 
    FILENAME = N'C:\Temp\FileTable\FileStreamDB_log.ldf',
    SIZE = 5MB, 
    MAXSIZE = 25MB, 
    FILEGROWTH = 5MB)
WITH FILESTREAM ( NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N'Docs' )
GO

SELECT 
	DB_NAME(database_id),
	non_transacted_access,
	non_transacted_access_desc
FROM sys.database_filestream_options;
GO

USE FileTableDB
GO

CREATE TABLE Documento AS FileTable
WITH ( 
    FileTable_Directory = 'Docs',
    FileTable_Collate_Filename = database_default
);
GO

-- Explore FileTable Directory
SELECT *
FROM dbo.Documento
go

INSERT INTO [dbo].Documento
([name],[file_stream])
SELECT 'MeuArquivoTexto.txt', CAST('FileTable is alive!!!!' AS VARBINARY(max)) AS FileData
GO

SELECT *
FROM dbo.Documento
go

INSERT INTO [dbo].Documento
([name],[file_stream])
SELECT 'PartTableAndIndexStrat.pdf', * FROM OPENROWSET(BULK N'C:\Temp\PartTableAndIndexStrat.pdf', SINGLE_BLOB) AS FileData
GO

-- Adicionar pasta
SELECT *
FROM dbo.Documento
go

-- Usos
DECLARE @root nvarchar(100);
DECLARE @fullpath nvarchar(1000);
  
SELECT @root = FileTableRootPath();
SELECT @fullpath = @root + file_stream.GetFileNamespacePath()
    FROM dbo.Documento
    WHERE name = N'PartTableAndIndexStrat.pdf';
  
PRINT @root;
PRINT @fullpath;

-- Abrir arquivo
SELECT * FROM sys.dm_filestream_non_transacted_handles;
GO

EXEC sp_kill_filestream_non_transacted_handles @handle_id = 533;
GO

IF OBJECT_ID('dbo.RegistroEvento', 'U') IS NOT NULL
	DROP TABLE dbo.RegistroEvento
GO

CREATE TABLE dbo.RegistroEvento (
	ID INT IDENTITY NOT NULL PRIMARY KEY
	, Nome VARCHAR(100) NOT NULL DEFAULT ('Sr. Nimbus')
	, DataRegistro DATETIME2 NOT NULL DEFAULT(SYSDATETIME())
)
GO

INSERT INTO dbo.RegistroEvento DEFAULT VALUES
GO

SELECT * FROM RegistroEvento

CREATE TRIGGER trgI_Documento 
ON dbo.Documento FOR INSERT
AS
BEGIN

	-- SELECT 10
	INSERT INTO RegistroEvento (Nome)
	SELECT i.Name
	FROM INSERTED AS i
END
go

SELECT * FROM RegistroEvento
go


BACKUP DATABASE FileTableDB
TO DISK = 'C:\temp\FileTableDB.BAK'
WITH INIT
go

DROP DATABASE FileTableDB

RESTORE DATABASE FileTableDB
FROM DISK = 'C:\temp\FileTableDB.BAK'



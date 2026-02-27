/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Demo 01 - Estrutura de índice cluster
	Descrição: Mostra a criação de um índice cluster e sua estrutura interna

		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/
USE master
go

-- SQL Server 2012
SELECT @@VERSION

-- Criando banco de dados e tabela para receber operações
IF (DB_ID('Mastering') IS NOT NULL)
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
  ON PRIMARY 
	(NAME = N'Mastering_Data01', 
	FILENAME = N'D:\Temp\SQLData\Mastering_Data01.mdf',
	SIZE = 150MB,
	MAXSIZE = 10GB,
	FILEGROWTH = 100MB)	
  LOG ON 
  (NAME = N'Mastering_Log', 
	FILENAME = N'D:\Temp\SQLData\Mastering_log1.ldf',
	SIZE = 50MB,
	MAXSIZE = 3GB,
	FILEGROWTH = 100MB)
go

USE Mastering
go

IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'Pessoa')
	DROP TABLE Pessoa
go

/*
	Temos um índice cluster aqui...
*/
CREATE TABLE Pessoa (
	Codigo BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	Nome CHAR(100) NOT NULL,
	CPF CHAR(11) NULL,
	Identidade VARCHAR(50) NULL,
	DataNascimento DATETIME NULL,
)
go

INSERT INTO Pessoa (Nome)
SELECT F.Fname + ' ' + L.LName
FROM tempdb.dbo.FirstName AS F
CROSS JOIN tempdb.dbo.LastName AS L
GO

SELECT TOP 300 * FROM Pessoa
go

SELECT * FROM sys.indexes
WHERE Object_ID = object_id('Pessoa')
GO

SELECT * FROM sys.sysindexes
WHERE id = object_id('Pessoa')
GO

SELECT AU.* 
FROM sys.allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
GO

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
GO

/*
	Quais são os valores para first_page, root_page e first_iam_page?
	0x260100000100	0x0D0300000100	0x270100000100
*/

-- Vamos analisar a first page?
DBCC TRACEON(3604)
DBCC PAGE (Mastering, 1, 294, 3)
go


-- Traduzindo a página
SELECT tempdb.dbo.fn_HexaToDBCCPAGE(0x140100000100)

SELECT 
	AU.* 
	, tempdb.dbo.fn_HexaToDBCCPAGE(AU.root_page) AS RootPage
	, tempdb.dbo.fn_HexaToDBCCPAGE(AU.first_iam_page) AS IAMPage
	, tempdb.dbo.fn_HexaToDBCCPAGE(AU.first_page) AS FirstPage
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
GO

/*
	Verifique para ver se os dados estão corretos.
	Lembre-se que o nível folha é uma lista duplamente encadeada
	
	Next page e prev page?
*/

/* Next */
DBCC PAGE (Mastering, 1, 305, 3)
go

/* Previous */
DBCC PAGE (Mastering, 1, ???, 3)
go


-- Vamos analisar a root page?
-- 0x??????	 = pag

DBCC PAGE (Mastering, 1, 781, 3)
go

-- SHOW EXECUTION PLAN
SET STATISTICS IO ON

SELECT * FROM Pessoa
WHERE Codigo = 20000

-- VAMOS SIMULAR O TRABALHO DA STORAGE ENGINE!
-- Navegando pela estrutura para ver como o SQL Server faz
DBCC PAGE (Mastering, 1, 781, 3)
go

DBCC PAGE (Mastering, 1, 782, 3)
go

DBCC PAGE (Mastering, 1, 643, 3)
go

/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Demo 03 - Estrutura de índice com include, composto e filtrado
	Descrição: 

		
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
	FILENAME = N'C:\Temp\Mastering_Data01.mdf',
	SIZE = 150MB,
	MAXSIZE = 10GB,
	FILEGROWTH = 100MB)	
  LOG ON 
  (NAME = N'Mastering_Log', 
	FILENAME = N'C:\Temp\Mastering_log1.ldf',
	SIZE = 50MB,
	MAXSIZE = 3GB,
	FILEGROWTH = 100MB)
go


-- **************************************************************************************
-- Demo 03.1) Índice include
-- **************************************************************************************

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

UPDATE dbo.Pessoa
SET
 	Identidade = CAST(Codigo AS VARCHAR) + ' SSP/DF'
	, CPF = CAST(Codigo + Codigo * 2 AS VARCHAR)
	, DataNascimento = DATEADD(D, Codigo / 5, '1977-01-01')
GO
	
SELECT * FROM Pessoa
go

SELECT
	OBJECT_NAME(object_id) AS ObjectName 
	, AU.* 
	, P.*
FROM SYS.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID IN (object_id('Pessoa'))
ORDER BY object_id, type
GO

-- 0x260100000100	0x0D0300000100	0x270100000100

SELECT Codigo, Nome, CPF
FROM dbo.Pessoa
WHERE CPF = '94605'
go




CREATE NONCLUSTERED INDEX idxNCL_Pessoa_CPF
ON dbo.Pessoa (CPF)
GO

SELECT
	OBJECT_NAME(object_id) AS ObjectName 
	, AU.* 
	, P.*
FROM SYS.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID IN (object_id('Pessoa'))
ORDER BY object_id, type
GO

SELECT Codigo, Nome, CPF
FROM dbo.Pessoa
WHERE CPF = '94605'
go


SET STATISTICS IO ON
-- Qual plano de execução?
SELECT Codigo, Nome, CPF
FROM dbo.Pessoa
WHERE CPF LIKE '94%'
GO



/* 
	INDEX INTERSECTION

SELECT Codigo, Nome, CPF
FROM dbo.Pessoa WITH(INDEX(1))
WHERE CPF LIKE '9%'
*/

-- Codigo, Nome, CPF ou *
SELECT Codigo, Nome, CPF
FROM dbo.Pessoa
WHERE CPF LIKE '9%'
GO





-- Índice com include
CREATE NONCLUSTERED INDEX idxNCL_Pessoa_CPFNome
ON dbo.Pessoa (CPF)
INCLUDE (Nome)
GO

SELECT
	OBJECT_NAME(object_id) AS ObjectName 
	, AU.* 
	, P.*
FROM SYS.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID IN (object_id('Pessoa'))
ORDER BY object_id, type
GO

/*
	Quais são os valores para first_page, root_page e first_iam_page?
	R: 0x702000000100	0x490100000100	0x4A0100000100
	
*/

-- Qual o novo plano de execução?
SELECT Codigo, Nome, CPF
FROM dbo.Pessoa
WHERE CPF LIKE '94%'
go

-- COVER INDEX!

-- Comparando os custos estimados dos planos
SELECT Codigo, Nome, CPF
FROM dbo.Pessoa
WHERE CPF LIKE '94%'
go
SELECT Codigo, Nome, CPF
FROM dbo.Pessoa WITH(INDEX(idxNCL_Pessoa_CPF))
WHERE CPF LIKE '94%'
go






-- Vamos analisar as estruturas
DBCC TRACEON(3604)
DBCC PAGE (Mastering, 1, 3376, 3)
go

DBCC PAGE (Mastering, 1, 329, 3)
go

-- Analisando nível intermediário
DBCC PAGE (Mastering, 1, 0000, 3)
go

-- Analisando nível folha
DBCC PAGE (Mastering, 1, 3186, 3)
go


-- Qual o plano de execução?
SELECT Codigo, Nome, CPF, Identidade
FROM dbo.Pessoa
WHERE CPF LIKE '94%'
go


-- **************************************************************************************
-- Demo 03.2) Índice composto
-- **************************************************************************************

-- Índice composto
CREATE NONCLUSTERED INDEX idxNCL_Pessoa_NomeData
ON dbo.Pessoa (Nome, DataNascimento)
GO

SELECT
	OBJECT_NAME(object_id) AS ObjectName 
	, AU.* 
	, P.*
FROM SYS.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID IN (object_id('Pessoa'))
ORDER BY object_id, type
GO

/*
	Quais são os valores para first_page, root_page e first_iam_page?
	R: 0x481300000100	0x6A1400000100	0x450900000100
		
*/

select Nome, DataNascimento
from dbo.Pessoa
order by DataNascimento

select Nome, DataNascimento
from dbo.Pessoa WITH(INDEX(1))
order by DataNascimento

SELECT *
FROM dbo.Pessoa
WHERE DataNascimento = '2008-09-20'
GO

SELECT *
FROM dbo.Pessoa WITH(INDEX(1))
WHERE DataNascimento = '2008-09-20'
go


-- Vamos analisar as raízes
DBCC TRACEON(3604)
DBCC PAGE (Mastering, 1, 5226, 3)
go

DBCC PAGE (Mastering, 1, 11553, 3)
go

-- Analisando nível intermediário de ambos os índices
DBCC PAGE (Mastering, 1, 0000, 3)
go

-- Analisando nível intermediário de ambos os índices
DBCC PAGE (Mastering, 1, 0000, 3)
go

-- Analisando nível folha do índice composto
DBCC PAGE (Mastering, 1, 0000, 3)
go


-- **************************************************************************************
-- Demo 03.3) Índice com filtro - O caso do campo de situação
-- **************************************************************************************

USE master
go

-- SQL Server 2008 R2
SELECT @@VERSION

-- Criando banco de dados e tabela para receber operações
IF (DB_ID('Mastering') IS NOT NULL)
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
  ON PRIMARY 
	(NAME = N'Mastering_Data01', 
	FILENAME = N'C:\Temp\Mastering_Data01.mdf',
	SIZE = 150MB,
	MAXSIZE = 10GB,
	FILEGROWTH = 100MB)	
  LOG ON 
  (NAME = N'Mastering_Log', 
	FILENAME = N'C:\Temp\Mastering_log1.ldf',
	SIZE = 50MB,
	MAXSIZE = 3GB,
	FILEGROWTH = 100MB)
go

USE Mastering
go

IF OBJECT_ID('RegistroFinanceiro') IS NOT NULL
	DROP TABLE RegistroFinanceiro
go

CREATE TABLE RegistroFinanceiro
(ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY
 , Valor NUMERIC NOT NULL
 , DadosExtras CHAR(30) NOT NULL DEFAULT ''
 , SituacaoPagamento CHAR(1) NOT NULL DEFAULT 'P')
go

DECLARE @I INT = 1
WHILE (@I<= 10000)
BEGIN
	INSERT INTO RegistroFinanceiro (Valor) VALUES (@I)
	SET @I += 1
END
go

UPDATE RegistroFinanceiro
	SET SituacaoPagamento = 'R'
WHERE ID % 1000 < 5

UPDATE RegistroFinanceiro
	SET SituacaoPagamento = 'A'
WHERE ID % 1000 = 6
go


/*
	P = Pago
	R = Recusado
	A = Aberto
*/
SELECT * FROM RegistroFinanceiro
go

-- Qual será o plano de execução?
SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'A'
GO

SET STATISTICS IO ON

CREATE NONCLUSTERED INDEX idxNCL_RegistroFinanceiro_SituacaoPagamento
ON RegistroFinanceiro (SituacaoPagamento)
GO

-- E agora, qual o plano?
SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'P'
GO

-- SQL Server está errado! Deve usar o NCL.
SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'P'

SELECT *
FROM RegistroFinanceiro AS R with(index(idxNCL_RegistroFinanceiro_SituacaoPagamento))
WHERE R.SituacaoPagamento = 'P'
GO

-- eerrr...
-- E agora?
SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'R'

SELECT *
FROM RegistroFinanceiro AS R with(index(idxNCL_RegistroFinanceiro_SituacaoPagamento))
WHERE R.SituacaoPagamento = 'R'
GO

-- Agora?
SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'A'
GO

SELECT 
	OBJECT_NAME(p.object_id) AS Objeto
	, I.name AS Indice, AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
INNER JOIN sys.indexes AS I
ON I.index_id = P.index_id
	AND I.object_id = P.object_id
WHERE P.object_id = OBJECT_ID('RegistroFinanceiro')
GO

-- Interessante, mas se a tabela tivesse 100.000 registros?
DECLARE @I INT = 10001
WHILE (@I<= 100000)
BEGIN
	INSERT INTO RegistroFinanceiro (Valor) VALUES (@I)
	SET @I += 1
END
go

SELECT OBJECT_NAME(p.object_id) AS Objeto, I.name AS Indice, AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
INNER JOIN sys.indexes AS I
ON I.index_id = P.index_id
	AND I.object_id = P.object_id
WHERE P.object_id = OBJECT_ID('RegistroFinanceiro')
GO

SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'R'
GO

-- Agora?
SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'A'
GO

CREATE NONCLUSTERED INDEX idxNCL_RegistroFinanceiro_SituacaoPagamentoFiltrado
ON RegistroFinanceiro (SituacaoPagamento)
WHERE SituacaoPagamento = 'A'
GO

-- Vamos verificar o tamanho dos índices...
SELECT OBJECT_NAME(p.object_id) AS Objeto, I.name AS Indice, AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
INNER JOIN sys.indexes AS I
ON I.index_id = P.index_id
	AND I.object_id = P.object_id
WHERE P.object_id = OBJECT_ID('RegistroFinanceiro')
GO

DBCC FREEPROCCACHE

-- Qual o plano?
SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'A'
GO

-- SQL Server que é isso? Usa o índice correto!
SELECT *
FROM RegistroFinanceiro AS R with(index(idxNCL_RegistroFinanceiro_SituacaoPagamentoFiltrado))
WHERE R.SituacaoPagamento = 'A'
GO

SELECT *
FROM RegistroFinanceiro AS R
WHERE R.SituacaoPagamento = 'A'
GO

-- Porque é exatamente igual?

SELECT 
	OBJECT_NAME(p.object_id) AS Objeto, I.name AS Indice, AU.*
	, tempdb.dbo.fn_HexaToDBCCPAGE(au.root_page)
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
INNER JOIN sys.indexes AS I
ON I.index_id = P.index_id
	AND I.object_id = P.object_id
WHERE P.object_id = OBJECT_ID('RegistroFinanceiro')
GO

/*
	Quais são os valores para first_page, root_page e first_iam_page?
	R: 
		0xAB0000000100	0xAE0000000100	0xAC0000000100
		0xC00300000100	0xC00300000100	0xF40000000100
*/

-- Sem filtro...
DBCC TRACEON(3604)
DBCC PAGE (Mastering, 1, 171, 3)
go

-- Com filtro
DBCC PAGE (Mastering, 1, 960, 3)
go
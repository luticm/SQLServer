/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Demo 03 - Estrutura de índice não-cluster e bookmark lookup
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

-- Este script é a continuação da demonstração 02, caso as estruturas de dados ainda 
-- não tenham sido criadas, o script comentado abaixo pode ser utilizado.

/*
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
*/

-- **************************************************************************************
-- Demo 03.1) CL + NCL
-- **************************************************************************************
USE Mastering
go

SET STATISTICS IO ON

-- DBCC DROPCLEANBUFFERS

-- O que pode ser feito para melhorar a forma de retornar o resultado dessa consulta?
select * from Pessoa
where Nome = 'Luciano Moreira'
GO



-- drop index Pessoa.idxNCL_Pessoa_Nome
CREATE NONCLUSTERED INDEX idxNCL_Pessoa_Nome
ON Pessoa (Nome)
go

SELECT * FROM sys.sysindexes
WHERE ID = object_id('Pessoa')
GO

-- 3 índices?

SELECT object_name(P.object_id), index_id, AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go

/*
	Quais são os valores para first_page, root_page e first_iam_page?
	R:
	0x260100000100	0x0D0300000100	0x270100000100
	0x500500000100	0xB20500000100	0x430500000100
	
*/

SET STATISTICS IO ON

/*
	Vamos ver quantas leituras foram feitas?
	Mostrar também o plano de execução!
*/

select * from Pessoa
where Nome = 'Luciano Moreira'




/*
	Hhhhuummm, 6 leituras de páginas.
	Vamos navegar a partir do nó raiz do índice não cluster e verificar o que o SQL Server está fazendo	
*/

DBCC PAGE (Mastering, 1, 1458, 3)
go

DBCC PAGE (Mastering, 1, 1425, 3)
go

DBCC PAGE (Mastering, 1, 1590, 3)
go


/*
	P1: O que temos no nível folha do índice cluster?
	P2: O que o SQL Server precisa fazer?
*/



/*
	R1: Ponteiros para os dados! RID ou Cluster key.
	R2: Navegar pela estrutura da tabela para encontrar as colunas faltantes na consulta.
*/

DBCC PAGE (Mastering, 1, 781, 3)
go

DBCC PAGE (Mastering, 1, 304, 3)
go

DBCC TRACEON(3604)

DBCC PAGE (Mastering, 1, 319, 3)
go



-- **************************************************************************************
-- Demo 03.2) Heap + NCL
-- **************************************************************************************

IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'PessoaHeap')
	DROP TABLE PessoaHeap
go

CREATE TABLE PessoaHeap (
	Codigo BIGINT IDENTITY(1,1) NOT NULL,
	Nome CHAR(100) NOT NULL,
	CPF CHAR(11) NULL,
	Identidade VARCHAR(50) NULL,
	DataNascimento DATETIME NULL,
)
go

INSERT INTO PessoaHeap (Nome)
SELECT F.Fname + ' ' + L.LName
FROM tempdb.dbo.FirstName AS F
CROSS JOIN tempdb.dbo.LastName AS L
go

CREATE NONCLUSTERED INDEX idxNCL_Pessoa_Nome
ON PessoaHeap (Nome)
go

SELECT * FROM sys.indexes
WHERE Object_ID = object_id('PessoaHeap')
go

SELECT object_name(P.object_id), index_id, AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('PessoaHeap')
go

/*
	Quais são os valores para first_page, root_page e first_iam_page?

	R:
	0x430500000100	0x000000000000	0x440500000100
	0x201000000100	0xE21000000100	0x550600000100
*/

-- Qual o número de logical reads que vamos ver na consulta abaixo?
select * from PessoaHeap
where Nome in ('Luciano Moreira','Luciano Silva',
	'Luciano Souza', 'Luciano Caixeta')
go



DBCC PAGE (Mastering, 1, 3490, 3)
go

DBCC PAGE (Mastering, 1, 3457, 3)
go

DBCC PAGE (Mastering, 1, 3621, 3)
go


/*
Qual o endereço que o SQL Server está referenciando?
R:

Palpites para a tradução desse endereço?



0x								
	Bookmark pointer	FileID		Slot #
						1:3017:0x29
*/
DBCC TRACEON(3604)
DBCC PAGE (Mastering, 1, 2377, 2)
go

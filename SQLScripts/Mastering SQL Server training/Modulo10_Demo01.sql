/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 09 - Isolation Levels
	Descrição: Analisa as características de cada nível de isolamento
		
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
go

CREATE TABLE Transacoes
(Codigo INT IDENTITY(1,1) NOT NULL,
 Nome VARCHAR(255) NOT NULL)
go

-- Default
INSERT INTO Transacoes VALUES ('Luciano Moreira')
go

select * from ::fn_dblog(null,null)

BEGIN TRANSACTION
	INSERT INTO Transacoes VALUES ('Joao José')
COMMIT TRANSACTION
go

SELECT @@TRANCOUNT

SET IMPLICIT_TRANSACTIONS ON
SELECT @@TRANCOUNT

INSERT INTO Transacoes VALUES ('Maria Aparecida')
SELECT @@TRANCOUNT
COMMIT

-- Cuidado!
SELECT * FROM Transacoes
SELECT @@TRANCOUNT
ROLLBACK

SET IMPLICIT_TRANSACTIONS OFF

-- Nested
BEGIN TRANSACTION
INSERT INTO Transacoes VALUES ('Senhorita 1')
SELECT @@TRANCOUNT
	BEGIN TRANSACTION
	INSERT INTO Transacoes VALUES ('Senhorita 2')
	SELECT @@TRANCOUNT
	ROLLBACK
SELECT @@TRANCOUNT
go

SELECT * FROM Transacoes
go

BEGIN TRANSACTION
	INSERT INTO Transacoes VALUES ('Senhorzinho 1')
	SELECT @@TRANCOUNT
		BEGIN TRANSACTION
		INSERT INTO Transacoes VALUES ('Senhorzinho 2')
		SELECT @@TRANCOUNT
		COMMIT
	SELECT @@TRANCOUNT
ROLLBACK
SELECT @@TRANCOUNT
go

-- Quem apareceu?
SELECT * FROM Transacoes
go

BEGIN TRANSACTION
	INSERT INTO Transacoes VALUES ('Senhorita 1')
	SELECT @@TRANCOUNT
		SAVE TRANSACTION Segmento01
		INSERT INTO Transacoes VALUES ('Senhorita 2')
		SELECT @@TRANCOUNT
		ROLLBACK TRAN Segmento01
	SELECT @@TRANCOUNT
COMMIT
go

SELECT * FROM Transacoes
go

BEGIN TRANSACTION
	INSERT INTO Transacoes VALUES ('Senhorzinho 2')
	SELECT @@TRANCOUNT
	BEGIN TRANSACTION
		SELECT @@TRANCOUNT
		SAVE TRANSACTION Segmento01
		INSERT INTO Transacoes VALUES ('Senhorzinho 3')
		SELECT @@TRANCOUNT
		COMMIT TRAN Segmento01
	SELECT @@TRANCOUNT
ROLLBACK
go

SELECT * FROM Transacoes
go

-- Isolation levels
USE Mastering
GO

IF EXISTS (SELECT [ID] FROM Sysobjects WHERE [Name] = 'Aluno' AND XType = 'U')
	DROP TABLE Aluno
GO

CREATE TABLE Aluno
(
	Codigo INT NOT NULL PRIMARY KEY,
	Nome VARCHAR(255)
)
GO

INSERT INTO Aluno VALUES (1, 'Alexandre')
INSERT INTO Aluno VALUES (2, 'Juliana')
INSERT INTO Aluno VALUES (3, 'Luciano')
INSERT INTO Aluno VALUES (4, 'Patricia')
GO

SELECT * FROM Aluno
GO

/*
	Conexão de análise
*/
select 
	TL.request_session_id,
	TL.request_type,
	TL.request_mode,
	TL.request_status,
	TL.resource_type,
	TL.resource_description,	
	TL.resource_database_id,
	*
from sys.dm_tran_locks AS TL
GO

SELECT * 
FROM sys.dm_tran_session_transactions AS ST
WHERE ST.is_user_transaction = 1

EXEC SP_LOCK
EXEC SP_WHO2

sp_whoisactive

SELECT @@SPID

/*
	READ COMMITTED
*/

-- Conexão 01
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

-- Conexão 02
BEGIN TRANSACTION
	UPDATE Aluno SET Nome = 'Carla' WHERE Codigo = 2
	
-- Conexão 01
SELECT * FROM Aluno
SELECT @@TRANCOUNT

-- Conexão 02
ROLLBACK TRANSACTION

/*
	READ UNCOMMITTED
*/

-- Conexão 01
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Conexão 02
BEGIN TRANSACTION
	UPDATE Aluno SET Nome = 'Carla' WHERE Codigo = 2
	
-- Conexão 01
-- Dirty read
SELECT * FROM Aluno

-- Conexão 02
ROLLBACK TRANSACTION

/*
	REPETEABLE READ
*/

-- Conexão 01
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

BEGIN TRANSACTION
	SELECT * FROM Aluno
	select @@TRANCOUNT

-- Conexão 02
-- ANALISA LOCKS

BEGIN TRANSACTION
	UPDATE Aluno SET Nome = 'Carla' WHERE Codigo = 2
COMMIT TRANSACTION
	
-- Conexão 01 (Ainda dentro da transação)
-- NON REPETEABLE READ
	SELECT * FROM Aluno
COMMIT TRANSACTION

-- Conexão 01
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

SELECT @@TRANCOUNT

BEGIN TRANSACTION
	SELECT * FROM Aluno

-- Conexão 02
-- ANALISA LOCKS

BEGIN TRANSACTION
	UPDATE Aluno SET Nome = 'Juliana' WHERE Codigo = 2
	-- STOP EXECUTION
ROLLBACK TRANSACTION

	SELECT * FROM Aluno

BEGIN TRANSACTION 
	INSERT INTO Aluno VALUES (5, 'Renata')
	-- Verificar LOCKs
COMMIT TRANSACTION

-- Conexão 01
-- PHANTOMS (Registro 5)
	SELECT * FROM Aluno
COMMIT TRANSACTION

/*
	SERIALIZABLE
*/

-- Conexão 01
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
select @@TRANCOUNT
BEGIN TRANSACTION
	SELECT * FROM Aluno

-- Conexão 02
-- ANALISA LOCKS

BEGIN TRANSACTION 
	INSERT INTO Aluno VALUES (6, 'Sabrina')
	-- STOP EXECUTION
ROLLBACK TRANSACTION

COMMIT


INSERT INTO Aluno VALUES (10, 'Sabrina1')
INSERT INTO Aluno VALUES (15, 'Sabrina2')
INSERT INTO Aluno VALUES (20, 'Sabrina3')
GO

SELECT * FROM aluno

-- Conexão 01
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
select @@TRANCOUNT
BEGIN TRANSACTION
	SELECT * FROM Aluno WHERE Codigo BETWEEN 5 and 17

	--SELECT * FROM aluno
	
BEGIN TRANSACTION 
	INSERT INTO Aluno VALUES (6, 'Sabrina')
	INSERT INTO Aluno VALUES (11, 'Sabrina')
	INSERT INTO Aluno VALUES (16, 'Sabrina')
	INSERT INTO Aluno VALUES (19, 'Sabrina')
	-- STOP EXECUTION
ROLLBACK TRANSACTION	

select * from aluno 
WHERE nome LIKE 'Sabrina%'
go


-- HEAPs
USE Mastering
GO

IF EXISTS (SELECT [ID] FROM Sysobjects WHERE [Name] = 'Aluno' AND XType = 'U')
	DROP TABLE Aluno
GO

CREATE TABLE Aluno
(
	Codigo INT NOT NULL,
	Nome VARCHAR(100)
)
GO

INSERT INTO Aluno VALUES (6, 'Sabrina')
INSERT INTO Aluno VALUES (11, 'Sabrina')
INSERT INTO Aluno VALUES (16, 'Sabrina')
INSERT INTO Aluno VALUES (19, 'Sabrina')
go

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
select @@TRANCOUNT

BEGIN TRANSACTION
	SELECT * FROM Aluno WHERE Codigo BETWEEN 7 and 12
  
select 
	TL.request_session_id,
	TL.request_type,
	TL.request_mode,
	TL.request_status,
	TL.resource_type,
	TL.resource_description,	
	TL.resource_database_id,
	*
from sys.dm_tran_locks AS TL
GO	

-- OBJECT lock = tabela toda com shared
 
COMMIT
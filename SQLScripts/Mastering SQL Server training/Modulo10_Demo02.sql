/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 09 - Transações e 
	Descrição: Analisa as características de cada nível de isolamento
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

-- Limitando número de locks...
USE AdventureWorks2012
GO

sp_configure 'locks', 5000
RECONFIGURE WITH override
GO

sp_configure 'locks'
GO

-- SQL Server restart

sp_configure 'locks', 0
RECONFIGURE WITH override
GO

ALTER TABLE sales.salesorderdetail
SET (LOCK_ESCALATION = DISABLE)
GO

UPDATE Sales.SalesOrderDetail WITH (ROWLOCK)
SET UnitPrice = UnitPrice 
go

ALTER TABLE sales.salesorderdetail
SET (LOCK_ESCALATION = AUTO)
GO


-- DEADLOCK
USE Mastering
go

IF OBJECT_ID('dbo.T1') IS NOT NULL
  DROP TABLE dbo.T1
IF OBJECT_ID('dbo.T2') IS NOT NULL
  DROP TABLE dbo.T2
GO


CREATE TABLE dbo.T1
(
  keycol INT         NOT NULL PRIMARY KEY,
  col1   INT         NOT NULL,
  col2   VARCHAR(50) NOT NULL
)

INSERT INTO dbo.T1(keycol, col1, col2) VALUES(1, 101, 'A')
INSERT INTO dbo.T1(keycol, col1, col2) VALUES(2, 102, 'B')
INSERT INTO dbo.T1(keycol, col1, col2) VALUES(3, 103, 'C')
go

CREATE TABLE dbo.T2
(
  keycol INT         NOT NULL PRIMARY KEY,
  col1   INT         NOT NULL,
  col2   VARCHAR(50) NOT NULL
)

INSERT INTO dbo.T2(keycol, col1, col2) VALUES(1, 201, 'X')
INSERT INTO dbo.T2(keycol, col1, col2) VALUES(2, 202, 'Y')
INSERT INTO dbo.T2(keycol, col1, col2) VALUES(3, 203, 'Z')
GO

SELECT * FROM dbo.T1
SELECT * FROM dbo.T2


-- Connection 1
BEGIN TRAN
  UPDATE dbo.T1 SET col1 = col1 + 1 WHERE keycol = 2
select @@trancount
-- Connection 2
GO
BEGIN TRAN
  UPDATE dbo.T2 SET col1 = col1 + 1 WHERE keycol = 2

exec sp_lock
  exec sp_who2

-- Connection 1
  SELECT col1 FROM dbo.T2
  exec sp_lock
  exec sp_who2
COMMIT TRAN


-- Connection 2
  SELECT col1 FROM dbo.T1 
COMMIT TRAN


-- O que apareceu no gráfico?
select *
from sys.partitions
where hobt_id = 72057594039238656
go

select object_name(325576198)

SELECT AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
where hobt_id = 72057594038845440
go

select *, %%lockres%%
from dbo.t1
go

select *, sys.fn_PhysLocFormatter(%%physloc%%)
from dbo.t1
where %%lockres%% = '(61a06abd401c)'
go

-- DEADLOCK ART

-- Snapshot Isolation
USE Master
GO

/*
ALTER DATABASE SnapshotInternals
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
*/

IF EXISTS (SELECT database_id FROM sys.databases WHERE name = 'SnapshotInternals')
BEGIN
	DROP DATABASE SnapshotInternals
END

CREATE DATABASE SnapshotInternals
GO

/*
	Mostra que por padrão o SNAPSHOT ISOLATION LEVEL ou o READ COMMITTED SNAPSHOT não estão habilitados, com
	exceção da master e msdb.
*/
-- Como a model está com o snapshot desabilitado, todos novos bancos também ficarão com ele desatibitado por padrão
SELECT [Name], snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on 
	FROM Sys.Databases
go

USE SnapshotInternals
GO

IF EXISTS (SELECT * FROM sys.all_objects WHERE Type = 'U' and name = 'SnapIsolation')
BEGIN
	DROP TABLE SnapIsolation
END

CREATE TABLE SnapIsolation
(
	Codigo INT Identity NOT NULL PRIMARY KEY,
	Nome VARCHAR(200) NOT NULL,
	VersaoLinha VARCHAR(100) NULL
)
GO

/*
	Vai dar erro? Se sim, quando?
*/
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
	SELECT @@TRANCOUNT	
	INSERT INTO SnapIsolation VALUES ('Snapshot desabilitado', '00_0001')
	SELECT @@TRANCOUNT
-- COMMIT TRANSACTION

/*
	No momento que o insert é executado, o erro é exibido
	
Msg 3952, Level 16, State 1, Line 5
Snapshot isolation transaction failed accessing database 'SnapshotInternals' because snapshot isolation 
	is not allowed in this database. Use ALTER DATABASE to allow snapshot isolation.
*/

/***************************************************************************************
 ***************************************************************************************
 
	Configura o snapshot_isolation
	Transaction level read consistency
*/
ALTER DATABASE SnapshotInternals
    SET ALLOW_SNAPSHOT_ISOLATION ON

ALTER DATABASE SnapshotInternals
    SET READ_COMMITTED_SNAPSHOT OFF
GO

SELECT [Name], snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on 
	FROM Sys.Databases
		WHERE [Name] = 'SnapshotInternals'
go

SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
	SELECT @@TRANCOUNT	
	INSERT INTO SnapIsolation VALUES ('Snapshot habilitado', '01_0001')	
COMMIT TRANSACTION
-- Agora tudo funcionou direitinho, mas para que eu uso esse nível de isolamento?

-- Mostra o que eu tenho antes de iniciar a transação
SELECT * FROM SnapIsolation

BEGIN TRANSACTION
	INSERT INTO SnapIsolation VALUES ('Snapshot habilitado_Ex02', '02_0001')	
	SELECT * FROM SnapIsolation
	SELECT @@TRANCOUNT
	
/*
	Em outra conexão executar:
		
	BEGIN TRANSACTION	
		SELECT * FROM SnapIsolation
		SELECT @@TRANCOUNT
	COMMIT TRANSACTION	
*/

	-- Analisamos o que temos.
	SELECT * FROM SnapIsolation

	-- Verificar o que aconteceu com a outra conexão
	SELECT @@SPID
	SELECT * FROM sys.sysprocesses where spid > 50
	/*
		Com o RC, a outra conexão fica bloqueada.
	*/
	
/*
	Em outra conexão executar:
	
	select @@TRANCOUNT
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT
	BEGIN TRANSACTION	
		SELECT * FROM SnapIsolation
		-- WITH (NOLOCK)
	COMMIT TRANSACTION
*/	
	
	SELECT * FROM SnapIsolation
	go
	
	UPDATE SnapIsolation
	SET VersaoLinha = '01_0002'
	WHERE Codigo = 1
	go
	
	SELECT * FROM SnapIsolation
	go
	
/*
	Em outra conexão executar a mesma consulta acima.
*/	
COMMIT TRANSACTION
/*
	E agora, o que vamos ver na outra conexão??
	R: Vemos o mesmo que estávamos vendo, pois a segunda transação ainda está aberta e retorna uma imagem
	consistente no tempo.
*/



/***************************************************************************************
 ***************************************************************************************
	
	Configura o read_committed snapshot - Não podem haver conexões no banco de dados
	Statement level read consistency	
*/
ALTER DATABASE SnapshotInternals SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
go

USE SnapshotInternals
go

ALTER DATABASE SnapshotInternals
    SET READ_COMMITTED_SNAPSHOT ON
GO

ALTER DATABASE SnapshotInternals SET MULTI_USER
go

SELECT [Name], snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on 
	FROM MASTER.Sys.Databases
	WHERE [Name] = 'SnapshotInternals'
go

/*
	Mostra a diferença entre o snapshot isolation level e o read committed snapshot
*/

SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION

	UPDATE SnapIsolation
	SET VersaoLinha = '01_0003'
	WHERE Codigo = 1
	
	SELECT * FROM SnapIsolation
	SELECT @@TRANCOUNT
	
	UPDATE SnapIsolation
	SET VersaoLinha = '01_0004'
	WHERE Codigo = 1
	
/*
	Em outra conexão executar:
	
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
		
	-- O SELECT é executado sem nenhum problema, mas a transação não concluída é ignorada.
	SELECT * FROM SnapIsolation
	
	
	-- Depois que a outra transação for concluída, executar o select novamente.
	-- O registro deve ser retornado, pois o snapshot é statemente level, não transaction level
	SELECT @@TRANCOUNT
	SELECT * FROM SnapIsolation
COMMIT TRANSACTION

*/		
	SELECT * FROM SnapIsolation
	go
	
/*
	Em outra conexão executar a mesma consulta acima.
*/	
COMMIT TRANSACTION -- (Depois)



-- Snapshot internals...

USE Master
GO

/*
ALTER DATABASE SnapshotInternals
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
*/

IF EXISTS (SELECT database_id FROM sys.databases WHERE name = 'SnapshotInternals')
BEGIN
	DROP DATABASE SnapshotInternals
END

CREATE DATABASE SnapshotInternals
GO

ALTER DATABASE SnapshotInternals
    SET ALLOW_SNAPSHOT_ISOLATION ON

ALTER DATABASE SnapshotInternals
    SET READ_COMMITTED_SNAPSHOT ON
GO

USE SnapshotInternals
GO

IF EXISTS (SELECT * FROM sys.all_objects WHERE Type = 'U' and name = 'SnapIsolation')
BEGIN
	DROP TABLE SnapIsolation
END

CREATE TABLE SnapIsolation
(
	Codigo INT Identity NOT NULL PRIMARY KEY,
	Nome VARCHAR(200) NOT NULL,
	VersaoLinha VARCHAR(100) NULL
)
GO

INSERT INTO SnapIsolation VALUES ('Registro 01', '01_0001')
INSERT INTO SnapIsolation VALUES ('Registro 02', '02_0001')
INSERT INTO SnapIsolation VALUES ('Registro 03', '03_0001')
INSERT INTO SnapIsolation VALUES ('Registro 04', '04_0001')
go

SELECT * FROM SnapIsolation
go

/*
	Vamos mostrar a version store crescendo através de DMVs...
*/

/***********************************************
-- Conexão Mestre
***********************************************/
SELECT @@SPID
SELECT * FROM sys.dm_tran_active_transactions
	WHERE name = 'user_transaction'
SELECT * FROM sys.dm_tran_version_store
SELECT * FROM sys.dm_tran_active_snapshot_database_transactions	


/***********************************************
-- T1 (Essa conexão)
***********************************************/
SELECT @@SPID
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION

	-- Analisa Conexão Mestre
	
	UPDATE SnapIsolation
		SET Nome = 'Registro 01 Versao 2',
			VersaoLinha = '01_0002'			
		WHERE Codigo = 1
		
	SELECT * FROM SnapIsolation
	-- Analisa Conexão Mestre
	-- Inicia T2
	SELECT @@TRANCOUNT		
COMMIT TRANSACTION
-- Analisar conexão mestre (note que transação T1 sumiu das DMVs)
-- MAS, versão original do registro deve ser mantido (veja que ele não é apagado), pois T2 ainda está aberto...
-- Iniciar T3


/***********************************************
-- T2 (Outra conexão)
***********************************************/
SELECT @@SPID
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION

	-- Analisa Conexão Mestre
	-- Nova transação ativa, mas não aparece na DMV de snapshot
		
	SELECT * FROM SnapIsolation
	-- Analisa Conexão Mestre
	-- Gera um XSN para esta transação e marca a transação anterior no XSN_snaphot
	-- Commit T1
	
	SELECT * FROM SnapIsolation
	-- Analisa Conexão Mestre
	-- Inicia T4
	
	SELECT @@TRANCOUNT
COMMIT TRANSACTION
-- Analisa a Conexão Mestre
-- Veja que o MinXSN é maior que a primeira versão armazenada na version store... O que acontecerá??
-- Commit T3


/***********************************************
-- T3 (Outra transação - pode reutilizar a conexão, mas usaremos outra por simplicidade)
***********************************************/
SELECT @@SPID
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
	
	UPDATE SnapIsolation
		SET Nome = 'Registro 01 Versao 3',
			VersaoLinha = '01_0003'			
		WHERE Codigo = 1
	
	SELECT * FROM SnapIsolation
	-- Analisa Conexão Mestre
	-- Continua T2
	
	SELECT @@TRANCOUNT	
COMMIT TRANSACTION
-- Analisa conexão mestre


/***********************************************
-- T4 (Outra conexão)
***********************************************/
SELECT @@SPID
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
		
	SELECT * FROM SnapIsolation
	-- Analisa Conexão Mestre	
	-- Note que XSN_snapshot inicia com o XSN X, pois Y já foi comitado
	-- Commit T2
	
	SELECT * FROM SnapIsolation
	-- Tudo está como esperávamos
	
	SELECT @@TRANCOUNT
COMMIT TRANSACTION
-- Analisa conexão mestre
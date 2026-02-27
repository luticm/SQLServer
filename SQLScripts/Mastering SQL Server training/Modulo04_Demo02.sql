/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 04 - Demo 02 - Mostra o transaction log e seus VLFs
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

use master
go

IF DB_ID('Mastering') IS NOT NULL
	DROP DATABASE Mastering
GO

CREATE DATABASE Mastering
ON PRIMARY
(NAME = 'Mastering',
	FILENAME = 'D:\Temp\SQLData\Mastering.mdf',
	SIZE = 15MB)
	LOG ON
	(NAME = 'Mastering_Log',
	FILENAME = 'D:\Temp\SQLData\Mastering.ldf',
	SIZE = 2MB)
go

USE Mastering
GO

DBCC LOGINFO()
go

IF (OBJECT_ID('TabelaLog') IS NOT NULL)
	DROP TABLE TabelaLog
go

CREATE TABLE TabelaLog
(Codigo INT IDENTITY NOT NULL, 
 Nome VARCHAR(1000) NOT NULL,
 PADDING CHAR(100) NOT NULL)
go

BACKUP DATABASE Mastering
TO DISK = 'D:\Temp\SQLData\Mastering.bak'
WITH INIT
GO

/*
Msg 3268, Level 16, State 1, Line 54
Cannot use the backup file 'D:\Temp\SQLData\Mastering.bak' because it was originally formatted with sector size 4096 and is now on a device with sector size 512.
Msg 3013, Level 16, State 1, Line 54
BACKUP DATABASE is terminating abnormally.
*/

INSERT INTO TabelaLog (Nome, PADDING) VALUES ('Luti', 'Sr. Nimbus')
go 1000

DBCC LOGINFO()
go

-- VLFs reutilizáveis?
CHECKPOINT
go

DBCC LOGINFO()
go

-- Só por curiosidade...
BACKUP LOG Mastering
WITH TRUNCATE_ONLY


-- Essa funcionalidade era para ter saído no SQL Server 2005, mas no dia de gerar o build do RTM um
-- cliente nos EUA ligou e pediu que a funcionalidade não fosse retirada. 
-- Fico imaginando quem fez a ligação...

SELECT * FROM fn_dblog(NULL, NULL)
go

-- Alguma transação aberta?
BACKUP LOG Mastering
TO DISK = 'D:\Temp\SQLData\Mastering.trn'
WITH INIT
go

/*
	O que vai acontecer com os VLFs?
*/
DBCC LOGINFO()
go

INSERT INTO TabelaLog (Nome, PADDING) VALUES ('Luti', 'Sr. Nimbus')
go 10000

DBCC LOGINFO()
go


-- select * from ::fn_dblog(null, null)
-- dbcc log(0, 0)

/*
	Notar: FSeqNo = 38 (pode mudar) é o primeiro VLF com paridade 128.
	Notar: CreateLSN dos outros e um novo VLF ainda não foi utilizado		
*/

BACKUP LOG Mastering
TO DISK = 'D:\Temp\SQLData\Mastering.trn'
WITH INIT
GO

DBCC LOGINFO()
go

/*
	Em uma outra conexão qualquer...
	
	USE Mastering
	BEGIN TRANSACTION
		INSERT INTO TabelaLog (Nome, PADDING) VALUES ('Luti', 'Sr. Nimbus')
		SELECT @@TRANCOUNT
*/

-- Inserir uma pequena massa de dados...
INSERT INTO TabelaLog (Nome, PADDING) VALUES ('Luti', 'Sr. Nimbus')
go 5000

DBCC LOGINFO()
go

DBCC TRACEON(3604)
DBCC TRACEON(3004)

-- Alguns VLFs utilizados, vamos fazer o backup para podermos reutilizar os VLFs...
BACKUP LOG Mastering
TO DISK = 'D:\Temp\SQLData\Mastering.trn'
WITH INIT
GO

-- O que vai acontecer quando mostrarmos o LOGINFO?
DBCC LOGINFO()
go

DBCC OPENTRAN()

SELECT log_reuse_wait_desc, name FROM sys.databases WHERE name = 'Mastering'
go

/*
R: Nada! MinLSN está segurando os VLFs
*/

-- Vamos fazer um rollback na transação da outra conexão
-- Após o rollback, o que aconteceu com os VLFs ativos?
DBCC LOGINFO()
go



-- R: Nada
-- Será que o checkpoint ajuda?
CHECKPOINT
DBCC LOGINFO()
go




-- R: nada
-- Alguns VLFs utilizados, vamos fazer o backup para podermos reutilizar os VLFs...
BACKUP LOG Mastering
TO DISK = 'D:\Temp\SQLData\Mastering.trn'
WITH INIT
GO


DBCC LOGINFO()
go

-- O que vai acontecer com o log nesse exemplo?
ALTER DATABASE Mastering
SET RECOVERY SIMPLE
go

INSERT INTO TabelaLog (Nome, PADDING) VALUES ('Luti', 'Sr. Nimbus')
go 50000

DBCC LOGINFO()
go

CHECKPOINT
go
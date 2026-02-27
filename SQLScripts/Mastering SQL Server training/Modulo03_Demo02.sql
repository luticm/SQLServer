/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 03 - Demo 02 - Alocação de páginas
	Descrição: Analisa o algoritmo de alocação de páginas do SQL Server e suas páginas
		de controle.
		
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
go

USE Mastering
go

IF EXISTS(SELECT 1 FROM SysObjects WHERE XType = 'U' and [ID] = Object_id('PageAllocation'))
	DROP TABLE PageAllocation
GO

-- HHHEEEAAAPPP!!!!
CREATE TABLE PageAllocation
(Codigo INT IDENTITY NOT NULL,
 Nome CHAR(8000) NOT NULL DEFAULT REPLICATE('X', 8000))
GO

SELECT * FROM MASTER..SYSDATABASES where [name] = 'Mastering'
-- Qual o DBID do Mastering: 11
SELECT object_id('PageAllocation')
-- Qual o objectid do PageAllocation: 1221579390


-- Para facilitar, faça um replace all do objectID
EXEC SP_SPACEUSED [PageAllocation]
DBCC EXTENTINFO(8, 1221579390, -1)
GO

INSERT INTO PageAllocation DEFAULT VALUES
GO

EXEC SP_SPACEUSED [PageAllocation]
DBCC EXTENTINFO(8, 1221579390, -1)
GO

-- Vamos inserir mais 7 registros = 7 páginas
INSERT INTO PageAllocation DEFAULT VALUES
go

EXEC SP_SPACEUSED [PageAllocation]
DBCC EXTENTINFO(8,1221579390, -1)
GO

INSERT INTO PageAllocation DEFAULT VALUES
go

EXEC SP_SPACEUSED [PageAllocation]
DBCC EXTENTINFO(8,1221579390, -1)
GO

INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
GO

EXEC SP_SPACEUSED [PageAllocation]
DBCC EXTENTINFO(8,1221579390, -1)
GO

/*
	Colar o resultado abaixo.
	P: Como saber quais páginas estão me mesmo extent?

1	294	1
1	304	1
1	305	1
1	306	1
1	307	1
1	308	1
1	309	1
1	310	1
*/
DBCC TRACEON(3604)





/*
	R: Faça as divisões por 8 para encontrar os limites de cada extent
*/

INSERT INTO PageAllocation DEFAULT VALUES
GO

/*
	P: o que acontecerá com o espaço utilizado?
*/
EXEC SP_SPACEUSED [PageAllocation]


/*
	R: alocação de um extent misto será maior que as alocações anteriores
*/
DBCC EXTENTINFO(8,1221579390, -1)
GO

-- Vamos continuar inserindo registros para mostrar que o modelo se mantém
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
INSERT INTO PageAllocation DEFAULT VALUES
GO

DBCC EXTENTINFO(8,1221579390, -1)
GO

EXEC SP_SPACEUSED [PageAllocation]
go

INSERT INTO PageAllocation DEFAULT VALUES
GO

EXEC SP_SPACEUSED [PageAllocation]

DBCC EXTENTINFO(8,1221579390, -1)
GO


/*
P: Estamos vendo um index size = 8KB e não existe nenhum índice nessa tabela (é uma heap). 
	De onde vêm esse valor?
		
1	294	1	1
1	304	1	1
1	305	1	1
1	306	1	1
1	307	1	1
1	308	1	1
1	309	1	1
1	310	1	1
1	312	8	8
1	320	1	8

R: index_size = 8KB é a página da IAM !!
*/


-- Vamos analisar GAM/SGAM/PFS?
DBCC TRACEON(3604)
-- PFS	    db_id, file_id, page_id
DBCC PAGE (Mastering, 1, 1, 3)

-- SGAM
DBCC PAGE (Mastering, 1, 3, 3)
-- Os resultados batem com o esperado pelo EXTENTINFO?

-- GAM
DBCC PAGE (Mastering, 1, 2, 3)

-- E A IAM?
SELECT * FROM sys.sysindexes
WHERE [id] = OBJECT_ID('PageAllocation')

0x1A0100000100
0xE20100000100

-- IAM
DBCC PAGE (Mastering, 1, 482, 3)

/*
	P: O que acontecerá quando for criao um índice cluster em Código?
	As páginas em extents não uniformes serão recolhidas?
*/
ALTER TABLE PageAllocation
ADD CONSTRAINT pk_PageAllocation
PRIMARY KEY (Codigo)
GO

EXEC SP_SPACEUSED [PageAllocation]
DBCC EXTENTINFO(8,1221579390, -1)
GO

select * from sys.system_internals_partitions

select * 
from sys.system_internals_allocation_units as IAU
inner join sys.system_internals_partitions as SIP
on IAU.container_id = SIP.partition_id
where sip.object_id = object_id('PageAllocation')
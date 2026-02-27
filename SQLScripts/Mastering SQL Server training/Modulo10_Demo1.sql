/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 10 - Row overflow
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE Master
go

IF Exists (SELECT * FROM sys.databases WHERE [name] = 'Mastering')
	DROP DATABASE Mastering
go

CREATE DATABASE Mastering
GO

USE Mastering
go

IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'RegistroGrande')
	DROP TABLE RegistroGrande
go

-- Vamos usar o overflow?
CREATE TABLE dbo.RegistroGrande
  (a varchar(3000),
   b varchar(3000),
   c varchar(3000),
   d varchar(3000))
 go

-- Posso usar o recurso do row overflow aqui?
CREATE TABLE dbo.RegistroGrande2
  (a varchar(10000))
 go
   
-- Vamos usar o overflow?
CREATE TABLE dbo.RegistroGrande2
  (a char(3000),
   b char(3000),
   c char(3000),
   d char(3000))
go   

   
SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('RegistroGrande')
go

INSERT INTO dbo.RegistroGrande
     SELECT REPLICATE('a', 200), REPLICATE('b', 200),
      REPLICATE('c', 200), REPLICATE('d', 200)
go
    
SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('RegistroGrande')
go

INSERT INTO dbo.RegistroGrande
     SELECT REPLICATE('e', 2100), REPLICATE('f', 2100),
      REPLICATE('g', 2100), REPLICATE('h', 2100)
go
      
SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('RegistroGrande')
go

DBCC IND (Mastering, RegistroGrande, -1)
GO
/*
1	295	NULL	NULL
1	294	1	295
1	298	1	295
1	297	NULL	NULL
1	296	1	297
*/

SELECT * FROM registrogrande

-- Primeria página de dados... (registro pequeno)
select DB_ID()
DBCC TRACEON(3604)
DBCC PAGE (Mastering,1,298, 1)
GO

-- Segunda página de dados...
DBCC PAGE (Mastering,1, 296, 1)
-- Está faltando uma letra?

-- Fazer o inverso, pegar o código da página de overflow, transformar
-- em hexa e verificar se encontra no ponteiro de oveflow.

-- Será?
DBCC PAGE (Mastering,1, 293, 3)
-- Muito bem!

USE master
GO
/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 05 - Demo 01 - Estrutura dos registros
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

IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'Pessoa')
	DROP TABLE Pessoa
go

CREATE TABLE Pessoa
(Codigo INT IDENTITY(1,1) NOT NULL,
 Nome VARCHAR(100) NOT NULL,
 Idade TINYINT NULL)
go

SELECT * 
FROM SYS.Tables
WHERE Object_ID = object_id('Pessoa')
go

SELECT * 
FROM SYS.Indexes
WHERE Object_ID = object_id('Pessoa')
go

SELECT * 
FROM SYS.sysindexes
WHERE id = object_id('Pessoa')
go

SELECT * 
FROM SYS.Partitions
WHERE Object_ID = object_id('Pessoa')
go

SELECT AU.* 
FROM SYS.Allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go

INSERT INTO Pessoa VALUES ('Luciano Caixeta Moreira', 36)
go

SELECT AU.* 
FROM SYS.Allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go

SELECT *
FROM sys.sysindexes
WHERE ID = object_id('Pessoa')
go

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go


/*
	Como analisar a posição da página?
	0x260100000100	0x000000000000	0x270100000100


*/

SELECT * FROM sys.sysfiles

DBCC TRACEON(3604)
DBCC PAGE (Mastering, 1, 294, 3) 
DBCC PAGE (Mastering, 1, 294, 2)
DBCC PAGE (Mastering, 1, 294, 1)
go

-- Vamos inserir uns registros
DECLARE @i INT
SET @i = 0

WHILE (@i < 100)
BEGIN
	INSERT INTO Pessoa VALUES (Replicate(CAST(@i AS VARCHAR), 30), @i)
	SET @i = @i + 1
END
go

SELECT * FROM Pessoa

-- Vamos pegar a primeira página de dados...
-- E ver com outras visualizações
DBCC PAGE (Mastering, 1, 294, 3)
DBCC PAGE (Mastering, 1, 294, 2)
DBCC PAGE (Mastering, 1, 294, 1)
go

/*
COLAR OFFSET ATÉ Slot #20

OFFSET TABLE:

Row - Offset                        
100 (0x64) - 7359 (0x1cbf)          
99 (0x63) - 7283 (0x1c73)           
98 (0x62) - 7207 (0x1c27)           
97 (0x61) - 7131 (0x1bdb)           
96 (0x60) - 7055 (0x1b8f)           
95 (0x5f) - 6979 (0x1b43)           
94 (0x5e) - 6903 (0x1af7)                

       
13 (0xd) - 747 (0x2eb)              
12 (0xc) - 671 (0x29f)              
11 (0xb) - 595 (0x253)              
10 (0xa) - 549 (0x225)              
9 (0x9) - 503 (0x1f7)               
8 (0x8) - 457 (0x1c9)               
7 (0x7) - 411 (0x19b)               
6 (0x6) - 365 (0x16d)               
5 (0x5) - 319 (0x13f)               
4 (0x4) - 273 (0x111)               
3 (0x3) - 227 (0xe3)                
2 (0x2) - 181 (0xb5)                
1 (0x1) - 135 (0x87)                
0 (0x0) - 96 (0x60)                 
        
Note a posição do primeiro registro! Pq?

*/

DELETE FROM Pessoa
WHERE (Codigo % 2) = 1
go

select * from Pessoa
go

DBCC PAGE (Mastering, 1, 294, 2)
go

checkpoint

-- O dado continua lá?
select * from Pessoa
go

DBCC PAGE (Mastering, 1, 291, 2)
go

-- Otimização, não precisa excluí-lo fisicamente, basta liberar o slot.
/*
COLAR OFFSET ATÉ Slot #20

Row - Offset   

100 (0x64) - 0 (0x0)                
99 (0x63) - 7283 (0x1c73)           
98 (0x62) - 0 (0x0)                 
97 (0x61) - 7131 (0x1bdb)           
96 (0x60) - 0 (0x0)                 
95 (0x5f) - 6979 (0x1b43)           
94 (0x5e) - 0 (0x0)                 
93 (0x5d) - 6827 (0x1aab)                  

                      
9 (0x9) - 503 (0x1f7)               
8 (0x8) - 0 (0x0)                   
7 (0x7) - 411 (0x19b)               
6 (0x6) - 0 (0x0)                   
5 (0x5) - 319 (0x13f)               
4 (0x4) - 0 (0x0)                   
3 (0x3) - 227 (0xe3)                
2 (0x2) - 0 (0x0)                   
1 (0x1) - 135 (0x87)                
0 (0x0) - 0 (0x0)            

              

*/

DECLARE @i INT
SET @i = 100

WHILE (@i < 150)
BEGIN
	INSERT INTO Pessoa VALUES (Replicate(CAST(@i AS VARCHAR), 20), @i)
	SET @i = @i + 1
END
go

-- O que aconteceu??
DBCC PAGE (Mastering, 1, 294, 2)
go

/*
COLAR OFFSET ATÉ Slot #20

99 (0x63) - 3670 (0xe56)             
98 (0x62) - 7470 (0x1d2e)            
97 (0x61) - 3594 (0xe0a)             
96 (0x60) - 7394 (0x1ce2)            
95 (0x5f) - 3518 (0xdbe)             
94 (0x5e) - 7318 (0x1c96)     

12 (0xc) - 4202 (0x106a)            
11 (0xb) - 326 (0x146)              
10 (0xa) - 4126 (0x101e)            
9 (0x9) - 280 (0x118)               
8 (0x8) - 4050 (0xfd2)              
7 (0x7) - 234 (0xea)                
6 (0x6) - 3974 (0xf86)              
5 (0x5) - 188 (0xbc)                
4 (0x4) - 3898 (0xf3a)              
3 (0x3) - 142 (0x8e)                
2 (0x2) - 3822 (0xeee)              
1 (0x1) - 96 (0x60)                 
0 (0x0) - 3746 (0xea2)                             

!! Note que as posições do slots se mantiveram!!!
*/


IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'Pessoa2')
	DROP TABLE Pessoa2
go

-- Usando um CHAR(100)
CREATE TABLE Pessoa2
(Codigo INT IDENTITY(1,1) NOT NULL,
 Nome CHAR(100) NOT NULL,
 Idade TINYINT NULL)
go

DECLARE @i INT
SET @i = 0

WHILE (@i < 100)
BEGIN
	INSERT INTO Pessoa2 VALUES (Replicate(CAST(@i AS VARCHAR), 30), @i)
	SET @i = @i + 1
END
go

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa2')
go


/*
	Veja como ficam espaços em branco...
*/
DBCC PAGE (Mastering, 1, 293, 2)
go

/* 
	P: Aonde está no cabeçalho as páginas prev e next?
	
	R: não vai aparecer, isso é uma HEAP! E agora?
		
	R: IAM
*/



/*
	Fowarding pointers
*/

IF Exists (SELECT * FROM sys.tables WHERE [name] = 'RegistroGrande')
	DROP TABLE RegistroGrande
go

CREATE TABLE RegistroGrande
(   a int IDENTITY,
    b varchar(1600),
    c varchar(1600));
GO

INSERT INTO RegistroGrande
    VALUES (REPLICATE('a', 1600), '')
INSERT INTO RegistroGrande
    VALUES (REPLICATE('b', 1600), '')
INSERT INTO RegistroGrande
    VALUES (REPLICATE('c', 1600), '')
INSERT INTO RegistroGrande
    VALUES (REPLICATE('d', 1600), '')
INSERT INTO RegistroGrande
    VALUES (REPLICATE('e', 1600), '')
GO

select *
from RegistroGrande

-- Outro jeito de ver as páginas de um objeto
DBCC IND (Mastering, RegistroGrande, -1)
-- 304

SELECT allocated_page_file_id, allocated_page_page_id, page_type_desc
     FROM sys.dm_db_database_page_allocations
        (db_id('AdventureWorks2012'), object_id('Sales.SalesOrderHeader'),
                NULL, NULL, 'DETAILED');

/*
	Outra abordagem para ver a página do registro...
*/
SELECT 
	SYS.fn_PhysLocFormatter(%%PHYSLOC%%) AS RID
	, %%PHYSLOC%% 
	, DB_ID(), * 
FROM RegistroGrande

/*
154
153
*/
DBCC TRACEON(3604)
DBCC PAGE (Mastering, 1, 304, 3)
DBCC PAGE (Mastering, 1, 304, 2)
go

UPDATE RegistroGrande
SET c = REPLICATE('x', 1600)
WHERE a = 3;
GO

select * from RegistroGrande
go

-- IAM
DBCC PAGE (Mastering, 1, 305, 3)
go

DBCC PAGE (Mastering, 1, 304, 3)
go

/*
Record Type = FORWARDING_STUB        Record Attributes =                  Record Size = 9

Memory Dump @0x000000000E54BFEB

0000000000000000:   042c0100 00010000 00                          .,.......


-- Como traduzir?
04 - Indica um fowarding pointer
*/

DBCC PAGE (Mastering, 1, 306, 1)
go

-- Alterando a tabela...
ALTER TABLE RegistroGrande
DROP COLUMN B
go

select * from RegistroGrande
go

DBCC PAGE (Mastering, 1, 304, 3)
go

/*
Slot 0 Column 67108865 Offset 0xf Length 0 Length (physical) 1600
DROPPED = NULL 
*/

SELECT * FROM sys.system_internals_partition_columns
WHERE partition_column_id = 67108865
go
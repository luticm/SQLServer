/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 02 - Demo 02 - SQL Server Memory
	Descrição: 
		
	* Copyright (C) 2012 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

/*
CREATE DATABASE MemUsage
GO

USE MemUsage
GO

IF OBJECT_ID('dbo.TabelaBase', 'U') IS NOT NULL
	DROP TABLE dbo.TabelaBase
GO

CREATE TABLE dbo.TabelaBase (
	ID INT IDENTITY NOT NULL PRIMARY KEY
	, Nome CHAR(8000) NOT NULL DEFAULT ('Sr. Nimbus')
	, DataRegistro DATETIME2 NOT NULL DEFAULT(SYSDATETIME())
)
GO

INSERT INTO dbo.TabelaBase DEFAULT VALUES
GO 100000
*/


USE master
go

sp_configure 'show', 1
reconfigure
go
sp_configure 'max server mem', '4500'
reconfigure
go

--	RESTART NO SQL Server

-- Olhar o bpool_visible / visible__target
-- Antigamente era comum vermos o número abaixo:
-- SELECT 204768 * 8192 bytes = PRINT 1677459456 / 1024 = 1.638.144 KB -- Pergunta: PQ esse valor?



-- R: Espaço do MemToLeave

-- Ver documentação...
SELECT *
FROM sys.dm_os_sys_info
GO

SELECT COUNT(*)
FROM AdventureWorks2012.Sales.SalesOrderDetail WITH(INDEX(1))
SELECT COUNT(*)
FROM AdventureWorks2012.Sales.SalesOrderHeader WITH(INDEX(1))
SELECT COUNT(*)
FROM MemUsage.dbo.TabelaBase WITH(INDEX(1))
go

SELECT *
FROM sys.dm_os_sys_info
GO

sp_configure 'max server mem', '1024'
RECONFIGURE

-- Perfmon Total Server Memory e Target Server Memory
SELECT * 
FROM sys.dm_os_sys_info
GO

-- Comparar com task manager
-- physical_memory_in_use_kb
SELECT *
FROM sys.dm_os_process_memory
GO

-- BPOOL_COMMMITED
-- Consegue fazer algum mapeamento com task manager? 
SELECT *
FROM sys.dm_os_sys_info
GO

-- database pages - hashed pages
-- Quantos registros?
SELECT TOP 1000 *
FROM sys.dm_os_buffer_descriptors
go

SELECT COUNT(*)
FROM sys.dm_os_buffer_descriptors
GO

-- select 105705 * 8 = 845640

-- Encontrar "Buffer Pool" 
DBCC MEMORYSTATUS()
go

-- Quais páginas estão em memória?
SELECT TOP 1000 *
FROM sys.dm_os_buffer_descriptors

DBCC DROPCLEANBUFFERS
GO

SELECT * FROM sys.databases
GO

-- Vamos trazer algumas páginas para a memória?
SELECT * FROM AdventureWorks.Sales.SalesOrderDetail
GO

SELECT *
FROM sys.dm_os_buffer_descriptors
WHERE database_id = db_id('AdventureWorks')
GO

-- ESCOLHENDO UMA PÁGINA QUALQUER PARA ANÁLISE... (olhar buffer descriptors)
DBCC TRACEON(3604)
DBCC PAGE (AdventureWorks, 1, 3180, 3)

-- Ver object_id no cabeçalho da página
SELECT OBJECT_NAME(1154103152, 7)

-- Lembra dos memory allocators que trabalham com hash tables (cache store)?
SELECT *
FROM sys.dm_os_memory_cache_hash_tables
ORDER BY name
go

SELECT * FROM sys.dm_os_memory_clerks

-- E agora, os clerks
SELECT *
FROM sys.dm_os_memory_clerks
order by pages_kb desc
GO

-- Porque estamos vendo tipos repetidos?
SELECT *
FROM sys.dm_os_memory_clerks
order by type
GO

-- ex.: MEMORYCLERK_SOSNODE - Node

select distinct mc.type, mo.type
from sys.dm_os_memory_clerks mc
join sys.dm_os_memory_objects mo
on mc.page_allocator_address = mo.page_allocator_address
WHERE mc.type = 'MEMORYCLERK_SOSNODE'
order by mc.type, mo.type

/*
	Endereço de memory allocators

select mc.type, mo.type, MO.* 
from sys.dm_os_memory_clerks mc
join sys.dm_os_memory_objects mo
on mc.page_allocator_address = mo.page_allocator_address
WHERE mc.type = 'MEMORYCLERK_SOSNODE'
order by mc.type, mo.type
*/

-- Exemplo MEMORYCLERK_SOSNODE
-- Existem subdivisões específicas para cada clerk

-- O que vemos para single_page?
-- <= SQL Server 2008 R2 era zero
SELECT *
FROM sys.dm_os_memory_clerks
WHERE type = 'MEMORYCLERK_SQLBUFFERPOOL' 
GO

-- Será que dá para fazer uma brincadeira usando o lock_manager?
USE AdventureWorks
GO

ALTER TABLE sales.salesorderdetail
SET (LOCK_ESCALATION = DISABLE)
GO

UPDATE Sales.SalesOrderDetail WITH (ROWLOCK)
SET UnitPrice = UnitPrice 
go

SP_LOCK

/*
	Isso vai levar um tempinho
	Em outra conexão...

	dbcc freesystemcache('all')
	
	while (1=1)
	BEGIN
	
		SELECT TOP 10 *
		FROM sys.dm_os_memory_clerks
		ORDER BY pages_kb DESC
		
		WAITFOR DELAY '00:00:03'
	
	END
	
	-- O que vemos???
*/

dbcc freesystemcache('all')

-- Voltando tudo ao normal...
ALTER TABLE sales.salesorderdetail
SET (LOCK_ESCALATION = AUTO)
go

-- Rounds count
SELECT * FROM sys.dm_os_memory_cache_clock_hands


dbcc memoryStatus()

select *
from sys.dm_xe_map_values
where name = 'wait_types'
	and map_value like '%compile%'

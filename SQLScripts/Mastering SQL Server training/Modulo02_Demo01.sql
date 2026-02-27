/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 02 - Demo 01 - Workers and Scheduling
	Descrição: 
		
	* Copyright (C) 2012 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

/*
Configurando o Max Worker Threads
*/

exec sp_configure 'show adv'

exec sp_configure 'show adv', 1
RECONFIGURE

exec sp_configure 'max worker', 0
RECONFIGURE

-- 37	max worker threads	128	32767	0	0

-- 256 + (N - 4) * 8 => 32 bits
-- 512 + (N - 4) * 16 => 64 bits

-- Aqui está a informação de qual é o valor do max_worker_threads que está valendo 
-- para o SQL Server.
select max_workers_count, * 
from sys.dm_os_sys_info
go

exec sp_configure 'max worker', 3000
RECONFIGURE
go

-- RESTART SQL SERVER até SQL Server 2008 R2
-- PQ?
exec sp_configure 'max worker'
go

select max_workers_count, * 
from sys.dm_os_sys_info
go

exec sp_configure 'max worker', 0
RECONFIGURE
go

select max_workers_count, * 
from sys.dm_os_sys_info
go

/*
	Schedulers
*/
USE master
go

SELECT * from sys.dm_os_nodes
go

SELECT *
FROM sys.dm_os_schedulers
go

-- SQL Server 2000
dbcc sqlperf(umsstats)

-- Será que bate com o total de threads do SQL Server no Task Manager?
SELECT *
FROM sys.dm_os_workers
go

-- E agora?
SELECT *
FROM sys.dm_os_threads

-- Não era para ser o mesmo número? Porque está diferente (mais threads)?
-- R: threads podem ser utilizadas internamente para outras funções de mais baixo nível

-- E agora, será que os workers são threads iniciadas pelo SQL Server?
SELECT *
FROM sys.dm_os_threads
WHERE started_by_sqlservr = 1
GO

SELECT *
FROM sys.dm_os_workers
go

SELECT *
FROM sys.dm_os_tasks
go
-- Não era para ser o mesmo número de workers? Porque está diferente (mais workers)?

SELECT * FROM sys.dm_exec_requests
WHERE session_id > 50
GO

SELECT * FROM sys.dm_exec_sessions
go

-- Verificar a relação de workers com schedulers
-- Note o affinity e CPU_ID
SELECT
	OW.affinity,
	OW.scheduler_address,
	OW.worker_address,
	OS.*
FROM sys.dm_os_workers AS OW
INNER JOIN sys.dm_os_schedulers OS
ON OW.scheduler_address = OS.scheduler_address
go

-- Olhar os schedulers que estão no fim...
SELECT
	OS.parent_node_id,
	OS.scheduler_id,
	OS.cpu_id,
	OW.worker_address,
	OW.affinity,	
	OW.scheduler_address,
	OS.load_factor
FROM sys.dm_os_workers AS OW
INNER JOIN sys.dm_os_schedulers OS
ON OW.scheduler_address = OS.scheduler_address
go

-- 1 RESOURCE MONITOR POR NUMA NODE
SELECT *
FROM sys.dm_exec_requests AS ER
INNER JOIN sys.dm_os_workers AS OW
ON ER.task_address = OW.task_address
where command = 'RESOURCE MONITOR'
go

SELECT *
FROM sys.dm_exec_requests AS ER
INNER JOIN sys.dm_os_workers AS OW
ON ER.task_address = OW.task_address
where command = 'LAZY WRITER'
go

EXEC SP_READERRORLOG

-- Monitorar com task manager
DECLARE @i INT=100000000
DECLARE @s VARCHAR(100)

WHILE (@i > 0)
BEGIN
	SELECT @s = @@VERSION
	SET @i -= 1
END	
go

-- Monitorando
SELECT 
	session_id,
	ER.status,
	worker_address,
	affinity,
	load_factor	
FROM sys.dm_exec_requests AS ER
INNER JOIN sys.dm_os_workers AS OW
ON ER.task_address = OW.task_address
INNER JOIN sys.dm_os_schedulers AS SC
ON SC.scheduler_address = OW.scheduler_address
where session_id > 50
go


-- Tenho 8 processadores em minha máquina, então o que estou fazendo é o mesmo do affinity mask = 0
-- 11111111 = 255

-- Testar novamente!
EXEC SP_CONFIGURE 'Affinity mask', 255
RECONFIGURE

EXEC SP_CONFIGURE 'Affinity mask'
GO

/*
	Para brincar em casa...

DBCC TRACESTATUS(-1)
DBCC TRACEON(8002, -1)
DBCC TRACEOFF(8002, -1)
*/



SELECT *
FROM SYS.dm_os_wait_stats
ORDER BY waiting_tasks_count DESC

-- 2 processadores
EXEC SP_CONFIGURE 'Affinity mask', 3
RECONFIGURE

EXEC SP_CONFIGURE 'Affinity mask'
GO

SELECT * FROM sys.dm_os_schedulers AS SC

-- Abrir múltiplas janelas com loop (4x ou 5x)
-- Monitorar com task manager
DECLARE @i INT=100000000
DECLARE @s VARCHAR(100)

WHILE (@i > 0)
BEGIN
	SELECT @s = @@VERSION
	SET @i -= 1
END	
go

-- Monitorando
SELECT 
	session_id,
	ER.status,
	worker_address,
	affinity,
	load_factor	
FROM sys.dm_exec_requests AS ER
INNER JOIN sys.dm_os_workers AS OW
ON ER.task_address = OW.task_address
INNER JOIN sys.dm_os_schedulers AS SC
ON SC.scheduler_address = OW.scheduler_address
where session_id > 50
go

select * from sys.dm_exec_requests AS ER

-- Signal wait time
SELECT *
FROM sys.dm_os_wait_stats
ORDER BY WAITING_TASKS_COUNT DESC
--WHERE wait_type LIKE '%SCHEDULER%'

DBCC SQLPERF('SYS.DM_OS_WAIT_STATS', CLEAR)

select *
from sys.dm_os_waiting_tasks
where session_id > 50


/*
-- worker preemptivo que acorda de tempos em tempos e é responsável por gerar notificações
-- Ex.: 17883 - nonidle thread has not yielded = uma aplicação que não o SQL Server está 
-- monopolizando o processador.
*/

/*
	If time permits: demonstração windbg
	bm *IsEscalationPossible*
*/
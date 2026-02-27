/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 08 - Plan Cache
	Descrição: 
		
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
GO

/*
	O que existe na cache de planos?
*/

-- A cache de planos
SELECT *
FROM sys.dm_exec_cached_plans as ECP
ORDER BY ecp.usecounts desc
go

-- Qual a diferença entre os dois?
SELECT TOP 10 *
FROM sys.dm_exec_query_stats as EQS
ORDER BY total_worker_time DESC
go



select * 
from sys.dm_exec_cached_plans as ECP
inner join sys.dm_exec_query_stats as EQS
on ECP.plan_handle = EQS.plan_handle
CROSS APPLY sys.dm_exec_sql_text(EQS.sql_handle)


-- O que está sendo executado
SELECT *
FROM sys.dm_exec_requests
WHERE session_id > 50
go

-- Por compatibilidade com o SQL Server 2000, mantida view
SELECT *
FROM sys.syscacheobjects
go

-- Usando o CROSS APPLY para ver o texto e o plano
SELECT *
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
GO

SELECT TOP 10 *
FROM sys.dm_exec_query_stats as EQS
CROSS APPLY sys.dm_exec_sql_text(EQS.sql_handle)
CROSS APPLY sys.dm_exec_query_plan(EQS.plan_handle)
ORDER BY eqs.total_worker_time desc
GO

-- Limpando tudo
DBCC FREEPROCCACHE

SELECT *
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
GO

/*
--
-- Parametrização AdHoc...
--
*/

-- Query plans parametrizados -> comportamento conservativo...
USE Northwind
go

SET STATISTICS IO ON
go

DBCC FREEPROCCACHE
go

SELECT * FROM Orders;
exec sp_help 'orders'
go

-- Alta seletividade
SELECT OrderID,  CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19980506'
GO

-- Baixa seletividade
SELECT OrderID,  CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19960101'
GO

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO

-- use count
SELECT OrderID,       CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19980506'
GO

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO

-- Baixa seletividade e use count (com espaço)
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19960101'
GO
-- Após consulta abaixo, executar a mesma consulta marcando (ou não) o GO.
-- O que aconteceu com os planos em cache???

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO


-- query_hash
SELECT *
FROM sys.dm_exec_query_stats as EQS
CROSS APPLY sys.dm_exec_sql_text(EQS.sql_handle)
CROSS APPLY sys.dm_exec_query_plan(EQS.plan_handle)
ORDER BY text desc
GO

-- AdHoc querying armazena os textos dos planos exatamente. Um espaço a mais gera planos diferentes em cache.

DBCC FREEPROCCACHE
go

-- E com filtro por OrderID?

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderID = 11074
GO

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderID = 10248
GO

-- Veja que o comportamento conservador do SQL Server permitiu a parametrização

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO

-- Outro orderId
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderID = 10549
GO

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO

SELECT OrderID,                    CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderID = 10248
GO
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderID = 10248
go

SELECT 
	ECP.*,
	EST.*,
	EQP.*
FROM sys.dm_exec_cached_plans AS ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.Plan_handle) AS EST
CROSS APPLY sys.dm_exec_query_plan(ECP.Plan_handle) AS EQP
go

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO

DBCC FREEPROCCACHE
go

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderID = 10248
GO

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderID = 102480
GO

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderID = CAST(102480 AS INT)
GO

SELECT *
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
ORDER BY text
GO

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate = '19980506'
GO

SELECT 
	ECP.*,
	EST.*,
	EQP.*
FROM sys.dm_exec_cached_plans AS ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.Plan_handle) AS EST
CROSS APPLY sys.dm_exec_query_plan(ECP.Plan_handle) AS EQP
ORDER BY EST.text
go

DBCC FREEPROCCACHE
GO



EXEC SP_EXECUTESQL N'SELECT OrderID, CustomerID, EmployeeID, OrderDate FROM dbo.Orders WHERE OrderID = @p', 
	N'@p INT', 
	10248
EXEC SP_EXECUTESQL N'SELECT OrderID, CustomerID, EmployeeID, OrderDate FROM dbo.Orders WHERE OrderID = @p', 
	N'@p INT', 
	102480


SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO


-- E AGORA?
EXEC SP_EXECUTESQL N'SELECT OrderID, CustomerID, EmployeeID, OrderDate FROM dbo.Orders WHERE OrderID = 10248'
EXEC SP_EXECUTESQL N'SELECT OrderID, CustomerID, EmployeeID, OrderDate FROM dbo.Orders WHERE OrderID = 102490'




SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO


/*
SQLCommand("SELECT * FROM TABELA WHERE coluna = @p1 and coluna2 = @p2"
SQLParameter P1 ("@P1", SQLBDTYPE.VARCHAR)
P1.VALUE = "abcd"
SQLParameter P2 ("@P2", SQLBDTYPE.VARCHAR)
P2.VALUE = "abcd"
comando.addparameter(p1);
comando.addParameter(p2);
comando.executereader();





SP_EXECUTESQL
VARCHAR(4), VARCHAR(4)
VARCHAR(3), VARCHAR(4)
VARCHAR(3), VARCHAR(5)
*/

/*
--
-- FORCE PARAMETRIZATION
--
*/

-- Parâmetro iniciado em 0 com Forced
-- Parâmetro iniciado em 1 com Simple
ALTER DATABASE Northwind
SET PARAMETERIZATION FORCED

DBCC FREEPROCCACHE

-- Alta seletividade
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19980506'
GO

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO

SET STATISTICS IO ON

DBCC FREEPROCCACHE

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19960101'
GO
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders WITH(INDEX(1))
WHERE OrderDate >= '19960101'
GO

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders WITH(INDEX(6))
WHERE OrderDate >= '19960101'
OPTION (RECOMPILE)
GO
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders 
WHERE OrderDate >= '19960101'
OPTION (RECOMPILE)
GO

-- Baixa seletividade
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19980506'
GO
SELECT OrderID, CustomerID, OrderDate, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= '19960101'
GO

SELECT
	EST.text
	, ECP.*
	, EST.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle) as EST
order by EST.text
GO

-- Foi ruim? Pareceu rápido...
-- Comparando o custo de I/O

ALTER DATABASE Northwind
SET PARAMETERIZATION SIMPLE


/*
--
-- OPTIMIZE FOR ADHOC WORKLOADS - SQL Server 2008
--
*/
EXEC SP_CONFIGURE 'advanced', 1
reconfigure
go

EXEC SP_CONFIGURE 'Optimize'
go

EXEC SP_CONFIGURE 'Optimize', 1
RECONFIGURE

EXEC SP_CONFIGURE 'Optimize'
go

DBCC FREEPROCCACHE
GO

-- Muda alguma coisa na parametrização das consultas? Isto é, o SQL Server vai parametrizar a consulta abaixo?
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19980506'
GO

SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19960101'
GO

-- O que mudou na plan cache? Veja tipo e plano de execução
SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- E se eu executar novamente a consulta?
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19980506'
GO

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

EXEC SP_CONFIGURE 'Optimize', 0
RECONFIGURE

EXEC SP_CONFIGURE 'Optimize'
go

/*
--
-- SPs
--
*/
DBCC FREEPROCCACHE
go

USE Northwind
GO
IF OBJECT_ID('dbo.usp_GetOrders') IS NOT NULL
  DROP PROC dbo.usp_GetOrders
GO

CREATE PROC dbo.usp_GetOrders
  @odate AS DATETIME
AS

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= @odate
GO

SP_HELP 'ORDERS'
SET STATISTICS IO ON
GO

-- Alta seletividade
EXEC dbo.usp_GetOrders '19980506'
GO

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- Baixa seletividade
EXEC dbo.usp_GetOrders '19960101'
go


-- Rápido e beleza. Comparando os custos...
EXEC dbo.usp_GetOrders '19960101'
go
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19960101'
GO

-- Tranquilo, mais barato. Mas estranho... E o IO?!

-- Qual o custo real?
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19960101'
go
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders with(index(OrderDate))
WHERE OrderDate >= '19960101'
go

-- O resultado acima está bom?? (execute os dois no mesmo batch)
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19960101'
go
SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '19980506'
go

-- A estimativa é o que está em cache!

-- PPPUUUTTTTZZZZZZZ!!!! E agora?
-- Chora? Desiste? Arquivo txt é melhor?


/*
	Primeira solução:
	WITH RECOMPILE na chamada
*/
DBCC FREEPROCCACHE

EXEC dbo.usp_GetOrders '19980506'
GO

-- UseCounts
SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- Recompile na chamada... Veja o plano de execução
exec dbo.usp_GetOrders '19960101'
WITH RECOMPILE



-- Porque o UseCounts não mudou???
SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- O SQL Server simplesmente não coloca o novo plano em cache, jogando-o fora.
-- Vamos ver o plano de execução se eu executar a instrução novamente, sem o recompile...
EXEC dbo.usp_GetOrders '19960101'
GO



-- sp_recompile 'usp_GetOrders'
-- DBCC FREEPROCCACHE(0x05000A00B982EE5AB02991980100000001000000000000000000000000000000000000000000000000000000)


-- OOOPPSSS, cuidado com isso!!!!
-- Qual o plano que estava em cache? WITH RECOMPILE na instrução não tira o procedimento de cache

ALTER PROC dbo.usp_GetOrders
  @odate AS DATETIME
AS

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= @odate
GO

/*
	Solução 2
	WITH RECOMPILE no procedimento	
*/
-- Agora o procedimento está com o with recompile
ALTER PROC dbo.usp_GetOrders
  @odate AS DATETIME
WITH RECOMPILE
AS

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= @odate
GO

DBCC FREEPROCCACHE
go

-- MOSTRANDO O PLANO..
EXEC dbo.usp_GetOrders '19980506'
GO

EXEC dbo.usp_GetOrders '19960101'
GO

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO
-- Aonde foi parar o meu plano???

-- R: não aparece em cache, pois o recompile não deixa o SQL Server colocar o plano lá 


/*
	Solução 03
	STATEMENT LEVEL RECOMPILE - SQL Server 2005 em diante
*/

-- STATEMENT LEVEL RECOMPILE (>= SQL Server 2005)
ALTER PROC dbo.usp_GetOrders
  @odate AS DATETIME
AS

-- ... Imagine várias instruções aqui ....

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= @odate

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= @odate
	OPTION(RECOMPILE)

-- ... Imagine várias instruções aqui ....
GO

DBCC FREEPROCCACHE
go

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- MOSTRANDO O PLANO..
EXEC dbo.usp_GetOrders '19980506'
GO

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- O que você espera ver como plano de execução deste procedimento?
EXEC dbo.usp_GetOrders '19960101'
GO
-- Legal, né?

-- Olhe o usecount...
SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
ORDER BY text
GO

-- PERGUNTA: como simular isso no SQL Server 2000???

-- R: SP -> SP with recompile


/*
--
-- Parameter sniffing + variáveis locais
--
*/
DBCC FREEPROCCACHE
go

INSERT INTO dbo.Orders(OrderDate, CustomerID, EmployeeID)
  VALUES(GETDATE(), N'ALFKI', 1);
GO

SELECT * FROM dbo.Orders
GO

ALTER PROC dbo.usp_GetOrders
  @d AS INT = 0
AS

	DECLARE @odate AS DATETIME;
	SET @odate = DATEADD(day, -@d, CONVERT(VARCHAR(8), GETDATE(), 112));

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= @odate	
GO

EXEC dbo.usp_GetOrders 1;
GO










DBCC SHOW_STATISTICS('Orders', orderdate)
go


UPDATE STATISTICS dbo.Orders
WITH FULLSCAN
GO


SELECT OrderID, CustomerID, EmployeeID, OrderDate
FROM dbo.Orders
WHERE OrderDate >= '20260101';
go


-- Clustered index scan, pq?

-- R: quando você utiliza NOVAS variáveis que são calculadas durante a execução do procedimento, SQL Server 
-- "chuta" uma cardinalidade para o resultado
-- Chuta = Magic Density
/*
	=			1 / densidade
	Between		9%
	> < >= e <=	30%
	
	Se não tiver estatísticas sobre densidade o magic density é 30%
*/





-- Expressões inline
ALTER PROC dbo.usp_GetOrders
  @d AS INT = 0
AS

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= DATEADD(day, -@d, CONVERT(VARCHAR(8), GETDATE(), 112));
GO




EXEC dbo.usp_GetOrders 1;
GO

DBCC FREEPROCCACHE
go

-- I had to change this from 10000 days to 20000 to make it work on 2026... Getting old....
EXEC dbo.usp_GetOrders 20000;
GO



ALTER PROC dbo.usp_GetOrders
  @d AS INT = 0
AS
	SET @d = @d + 20000

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= DATEADD(day, - (@d), CONVERT(VARCHAR(8), GETDATE(), 112))
go


DBCC FREEPROCCACHE

EXEC dbo.usp_GetOrders 1;
GO

ALTER PROC dbo.usp_GetOrders
  @d AS INT = 0
AS
	SET @d = @d + 20000

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= DATEADD(day, - (@d), CONVERT(VARCHAR(8), GETDATE(), 112))
	OPTION(RECOMPILE)
go





-- Plano em cache ruim, reusa plano ruim. Já aprendeu, não é?
DBCC FREEPROCCACHE
GO

-- P: o que fazer para que o SQL Server guarde a SP com um parâmetro que seja aceitável na média?

-- R: SQL Server 2000 -> gataiada - forca execução após limpeza da cache ou startup proc
-- R: SQL Server 2005 -> OPTIMIZE FOR HINT

-- OPTIMIZE FOR
ALTER PROC dbo.usp_GetOrders
  @d AS INT = 0
AS

	DECLARE @odate AS DATETIME;
	SET @odate = DATEADD(day, -@d, CONVERT(VARCHAR(8), GETDATE(), 112));

	SELECT OrderID, CustomerID, EmployeeID, OrderDate
	FROM dbo.Orders
	WHERE OrderDate >= @odate
	OPTION(OPTIMIZE FOR(@odate = '99991231'));
	--OPTION(OPTIMIZE FOR UNKNOWN);
GO

-- Valor extremamente seletivo, concordam?

-- Qual plano que esperaríamos aqui se não houvesse a hint?
-- E com a hint?
EXEC dbo.usp_GetOrders 10000;
GO

-- Tuning fino...
ALTER PROC dbo.usp_GetOrders
  @d AS INT = 0
AS

	if (@d > 5000) 
	begin
		SELECT OrderID, CustomerID, EmployeeID, OrderDate
		FROM dbo.Orders
		WHERE OrderDate >= DATEADD(day, -@d, CONVERT(VARCHAR(8), GETDATE(), 112))
	end
	else
	begin
		SELECT OrderID, CustomerID, EmployeeID, OrderDate
		FROM dbo.Orders
		WHERE OrderDate >= DATEADD(day, -@d, CONVERT(VARCHAR(8), GETDATE(), 112))
	end
GO


EXEC dbo.usp_GetOrders 1;
GO

EXEC dbo.usp_GetOrders 10000;
GO

SELECT 
	ECP.*,
	EST.*,
	EQP.*
FROM sys.dm_exec_cached_plans AS ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.Plan_handle) AS EST
CROSS APPLY sys.dm_exec_query_plan(ECP.Plan_handle) AS EQP
go


ALTER PROC dbo.usp_GetOrders
  @d AS INT = 0
AS

	if (@d > 5000) 
	begin
		SELECT OrderID, CustomerID, EmployeeID, OrderDate
		FROM dbo.Orders
		WHERE OrderDate >= DATEADD(day, -@d, CONVERT(VARCHAR(8), GETDATE(), 112))
		OPTION(OPTIMIZE FOR(@d = 10000))
	end
	else
	begin
		SELECT OrderID, CustomerID, EmployeeID, OrderDate
		FROM dbo.Orders
		WHERE OrderDate >= DATEADD(day, -@d, CONVERT(VARCHAR(8), GETDATE(), 112))
		OPTION(OPTIMIZE FOR(@d = 1))
	end
GO


-- Test proc
EXEC dbo.usp_GetOrders 1;
GO

EXEC dbo.usp_GetOrders 5001;
GO


-- Cleanup
DELETE FROM dbo.Orders WHERE OrderID > 11077;
GO
IF OBJECT_ID('dbo.usp_GetOrders') IS NOT NULL
  DROP PROC dbo.usp_GetOrders;
GO

USE master
GO
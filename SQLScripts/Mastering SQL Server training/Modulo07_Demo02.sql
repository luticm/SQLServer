/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 07 Demo 02 - Query Optimizer e paralelismo
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/
use AdventureWorks2012
GO

-- Lembrar do script Make adventureworks big (Adam Machanic)

sp_configure 'max deg'

-- Analisando um plano de execução paralelo
select count(*)
from dbo.bigTransactionHistory
GO



DBCC FREEPROCCACHE;

-- ESTIMATED PLAN
select ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
GROUP BY ProductID
go

select ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
WHERE ProductID between 1001 and 1010
GROUP BY ProductID
go

select ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
WHERE ProductID between 1001 and 2833
GROUP BY ProductID
go

SET STATISTICS IO, TIME ON

SELECT ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
WHERE ProductID between 1001 and 2834
GROUP BY ProductID
go






-- Analisar CPU cost do Index Seek
select ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
WHERE ProductID between 1001 and 2834
GROUP BY ProductID
OPTION (MAXDOP 1)

-- R: 1.14303

select ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
WHERE ProductID between 1001 and 2834
GROUP BY ProductID
OPTION (MAXDOP 2)

-- R: 0.5715

select 0.5715 / 2.0
-- 0.2857500

select ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
WHERE ProductID between 1001 and 2834
GROUP BY ProductID
OPTION (MAXDOP 4)

-- R: 
select 0.28592 * 4

select ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
WHERE ProductID between 1001 and 2835
GROUP BY ProductID
OPTION (MAXDOP 8)

-- R: 
-- PQ?




DBCC OPTIMIZER_WHATIF(CPUs, 16) WITH NO_INFOMSGS;

select ProductID, count(TransactionID), sum(Quantity), sum(ActualCost)
from dbo.bigTransactionHistory
WHERE ProductID between 1001 and 2834
GROUP BY ProductID
OPTION (MAXDOP 8);

DBCC OPTIMIZER_WHATIF(ResetAll) WITH NO_INFOMSGS;

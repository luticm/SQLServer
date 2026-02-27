/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 07 Demo 01 - Planos de execução e QO
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE Northwind
go

SELECT * FROM Products
SELECT * FROM Suppliers
SELECT * FROM [Order Details]
go

-- Analisando um plano de execução...
SELECT p.ProductName, p.UnitPrice, s.CompanyName
	, s.Country, od.quantity
FROM Products as P 
inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE P.CategoryID in (1,2,3) and P.Unitprice < 20 
	and S.Country = 'uk' and od.Quantity < 30
--OPTION(QUERYTRACEON 9481)
GO

-- drop index [order details].idx_Cobreconsulta

sp_helpindex '[order details]'
sp_help '[order details]'

select * from sys.index_columns
where object_id = object_id('order details')

create nonclustered index idx_Cobreconsulta
ON [Order Details] (productId)
INCLUDE (Quantity)


SELECT p.ProductName, p.UnitPrice, s.CompanyName, s.Country, od.quantity
FROM Products as P 
inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od 
on p.productID = od.productid
WHERE P.CategoryID in (1,2,3) 
	and P.Unitprice < 20
	and S.Country = 'uk' 
	and od.Quantity < 30
GO

SELECT p.ProductName, p.UnitPrice, s.CompanyName, s.Country, od.quantity
FROM Products as P 
inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od with(index(ProductID))
on p.productID = od.productid
WHERE P.CategoryID in (1,2,3) 
	and P.Unitprice < 20
	and S.Country = 'uk' 
	and od.Quantity < 30
GO

DROP INDEX [order details].idx_Cobreconsulta
GO

-- Optimizer trabalhando
USE AdventureWorks2012
go

SP_HELP 'Sales.SalesOrderDetail'
go

select top 1000 * from Sales.SalesOrderDetail
go

DBCC FREEPROCCACHE

-- Note o aggregate que representa o group by
SELECT 
	SUM(SOD.UnitPrice * SOD.OrderQty) AS Total
FROM Sales.SalesOrderDetail AS SOD
GROUP BY SOD.SalesOrderDetailID
go

SELECT 
	SUM(SOD.UnitPrice * SOD.OrderQty) AS Total
FROM Sales.SalesOrderDetail AS SOD
GROUP BY SOD.SalesOrderDetailID, SOD.SalesOrderID
GO



USE Northwind
GO

SET SHOWPLAN_TEXT ON
go

SELECT *
FROM Products AS P
WHERE P.UnitPrice < 20
ORDER BY P.ProductName
GO

SET SHOWPLAN_TEXT OFF
GO
SET SHOWPLAN_ALL ON
go

SELECT *
FROM Products AS P
INNER JOIN Categories AS C
ON C.CategoryID = P.CategoryID
WHERE P.UnitPrice < 20
ORDER BY P.ProductName
GO

SET SHOWPLAN_ALL OFF
go
SET STATISTICS PROFILE ON
go

SELECT *
FROM Products AS P
INNER JOIN Categories AS C
ON C.CategoryID = P.CategoryID
WHERE P.UnitPrice < 20
ORDER BY P.ProductName
GO

select * from sys.sysprocesses

SET STATISTICS PROFILE OFF
go
SET STATISTICS XML ON
go

SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID in (1,2,3) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO

SET STATISTICS XML OFF
go

DBCC FREEPROCCACHE
GO

-- IN ou NOT IN???
SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID NOT IN (4,5,6,7,8) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO

SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID in (1,2,3) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO

-- Contradição
SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE (CategoryID = 2 AND CategoryID = 3) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO

-- OR = VS. > <
SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
INNER join [order details] as od
on p.productID = od.productid
WHERE (CategoryID = 2 OR CategoryID = 3) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO

SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID > 1 AND CategoryID < 4 and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO


SET STATISTICS IO ON
SET STATISTICS TIME ON


/*
	Segunda etapa
	SARG e NON-SARG
	
	D = Default
	B = Blame
	A = Accepter
*/

-- Vamos ver os índices, 
exec sp_helpindex 'Orders'
go
SET STATISTICS IO ON

select * from orders


-- Está usando o índice, então beleza!
SELECT OrderID, OrderDate
FROM Orders
WHERE MONTH(OrderDate) = 8 
	AND YEAR(OrderDate) = 1996
	
-- SERÁ?
select OrderID, OrderDate 
from Orders
where OrderDate between '19960801' and '19960831 23:59:59.997'

-- CONVERT DATE


select OrderID, OrderDate, convert(char(10), OrderDate, 103) 
from Orders
where convert(char(10), OrderDate, 103) between '01/08/1996' and '31/08/1996'

select OrderID, OrderDate 
from Orders
where CONVERT(CHAR(6), OrderDate, 112) = '199608'


SELECT ProductID, ProductName
FROM dbo.Products
WHERE ProductName LIKE 'ch%'


SELECT ProductID, ProductName
FROM dbo.Products
WHERE  1 = CHARINDEX('ch', ProductName, 0)






-- E esse aqui?
SELECT *
FROM dbo.Products
WHERE ProductID * 10 = 100





go












SELECT *
FROM dbo.Products
WHERE ProductID = 100 / 10
go


-- Execute os dois juntos e compare.
-- SEEK vs. SCAN?

/*
	Não é falta de índice, mas sim um problema com a forma que foi escrita a consulta!
	Depois têm muita gente falando que se o banco está devagar é sempre culpa do DBA.
	
	D = Default
	B = Blame
	A = Accepter
*/

-- Mais info

SELECT * 
FROM sys.dm_exec_query_optimizer_info;

SELECT * FROM sys.dm_exec_query_transformation_stats
DBCC RULEOFF('JoinWithCTGToSel')
DBCC RULEON('JoinWithCTGToSel')
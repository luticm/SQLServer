USE AdventureWorksBig
GO

-- 2121 rows
-- NULL	1290065
SELECT ModifiedDate, count(*)
FROM Sales.SalesOrderHeaderBig
group by ModifiedDate
WITH ROLLUP
order by ModifiedDate ASC

-- 1124 rows
-- NULL	31465
SELECT ModifiedDate, count(*)
FROM Sales.SalesOrderHeader
group by ModifiedDate
WITH ROLLUP
order by ModifiedDate ASC

SELECT top 100 *
FROM Sales.SalesOrderDetail

-- 1125 rows
-- NULL	4973997
SELECT ModifiedDate, count(*)
FROM Sales.SalesOrderDetailBig
group by ModifiedDate
WITH ROLLUP
order by ModifiedDate ASC

-- 1124 rows
-- NULL	121317
SELECT ModifiedDate, count(*)
FROM Sales.SalesOrderDetail
group by ModifiedDate
WITH ROLLUP
order by ModifiedDate ASC

--select db_id('AdventureWorksBig')
--select db_name(9)

select top 100 * 
from sys.dm_os_buffer_descriptors

select db_name(database_id), database_id, (count(*) * 8) / 1024 AS BPUsageMB
from sys.dm_os_buffer_descriptors
group by database_id 

where database_id = db_id('AdventureWorksBig')







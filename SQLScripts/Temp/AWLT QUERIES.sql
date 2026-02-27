-- Created by GitHub Copilot in SSMS - review carefully before executing
-- 1. Get top 5 customers by total sales
SELECT TOP 5
    c.CustomerID,
    c.FirstName,
    c.LastName,
    SUM(soh.TotalDue) AS TotalSales
FROM SalesLT.SalesOrderHeader soh
JOIN SalesLT.Customer c ON soh.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSales DESC;

-- 2. List products with inventory below 100
SELECT *
FROM SalesLT.Product p;

-- 3. Get recent orders in the last 30 days
SELECT
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    c.CompanyName
FROM SalesLT.SalesOrderHeader soh
JOIN SalesLT.Customer c ON soh.CustomerID = c.CustomerID
-- WHERE soh.OrderDate >= DATEADD(DAY, -30, GETDATE())
ORDER BY soh.OrderDate DESC;

-- 4. Count orders per customer
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    COUNT(soh.SalesOrderID) AS OrderCount
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY OrderCount DESC;

-- 5. Query performance insights
SELECT TOP 10 
    rs.avg_duration AS AvgDurationMs,
    SUM(rs.count_executions) AS TotalExecutions,
    qsq.query_id,
    LEFT(qst.query_sql_text, 100) AS query_text_snippet,
    CASE 
        WHEN qsq.object_id = 0 THEN N'Ad-hoc'
        ELSE OBJECT_NAME(qsq.object_id)
    END AS ObjectName
FROM sys.query_store_query qsq
JOIN sys.query_store_query_text qst ON qsq.query_text_id = qst.query_text_id
JOIN sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
JOIN sys.query_store_runtime_stats rs ON qsp.plan_id = rs.plan_id
WHERE rs.last_execution_time > DATEADD(HOUR, -1, GETUTCDATE())
  AND rs.execution_type = 0
GROUP BY rs.avg_duration, qsq.query_id, qst.query_sql_text, qsq.object_id
ORDER BY rs.avg_duration DESC;


select *
from sys.query_store_query as qsq

select *
from sys.query_store_query_text

select *
from sys.query_store_query as qsq
inner join sys.query_store_query_text as qsqt
on qsq.query_text_id = qsqt.query_text_id


SELECT actual_state_desc, current_storage_size_mb, max_storage_size_mb
FROM sys.database_query_store_options;


select * from Sys.dm_exec_query_optimizer_info


select *
from sys.dm_exec_cached_plans




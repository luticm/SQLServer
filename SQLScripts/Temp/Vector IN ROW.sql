
select count(*) from dbo.netflix_titles2;
select count(*) from ai.netflix_titles;

select top 10 * from dbo.netflix_titles2;
select top 10 * from ai.netflix_titles;

SELECT 
    t.name AS table_name,
    au.type_desc,
    au.total_pages,
    au.used_pages
FROM sys.tables t
JOIN sys.partitions p 
    ON t.object_id = p.object_id
JOIN sys.allocation_units au 
    ON p.partition_id = au.container_id
WHERE t.object_id = object_id('dbo.netflix_titles2')
    and index_id = 0; -- Heap only

--netflix_titles2	IN_ROW_DATA	857	854
--netflix_titles2	LOB_DATA	0	0
--netflix_titles2	ROW_OVERFLOW_DATA	0	0


SELECT     
    t.name AS table_name,
    au.type_desc,
    au.total_pages,
    au.used_pages
FROM sys.tables t
JOIN sys.partitions p 
    ON t.object_id = p.object_id
JOIN sys.allocation_units au 
    ON p.partition_id = au.container_id
WHERE t.object_id = object_id('ai.netflix_titles')
    and index_id = 0; -- Heap only

--netflix_titles	IN_ROW_DATA	8817	8809
--netflix_titles	LOB_DATA	249	247
--netflix_titles	ROW_OVERFLOW_DATA	0	0


select 8807 / (854 * 1.0) as PageDensity,
    8807 / (8809 * 1.0) as PageDensity;
    


CREATE TABLE ai.netflix_titles2 (
    show_id VARCHAR(10) PRIMARY KEY NOT NULL,
    show_type VARCHAR(20) NOT NULL,
    title VARCHAR(1000) NOT NULL,
    director VARCHAR(250) NULL,
    show_cast TEXT  NULL,
    country VARCHAR(1000) NULL,
    date_added VARCHAR(100) NULL,
    release_year INT  NOT NULL,
    rating VARCHAR(10) NULL,
    duration VARCHAR(100)  NULL,
    listed_in VARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX)  NOT NULL,
    document_vector VECTOR(1536) NULL
);

INSERT INTO ai.netflix_titles2
SELECT * FROM ai.netflix_titles;

SELECT     
    t.name AS table_name,
    au.type_desc,
    au.total_pages,
    au.used_pages
FROM sys.tables t
JOIN sys.partitions p 
    ON t.object_id = p.object_id
JOIN sys.allocation_units au 
    ON p.partition_id = au.container_id
WHERE t.object_id = object_id('ai.netflix_titles2')
    and index_id = 1; -- CI

--netflix_titles2	IN_ROW_DATA	8873	8852
--netflix_titles2	LOB_DATA	249	246
--netflix_titles2	ROW_OVERFLOW_DATA	0	0
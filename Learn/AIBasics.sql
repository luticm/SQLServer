USE AdventureWorksLT
go

select @@VERSION

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd.azuresql'; -- Replace with a strong password

--CREATE CREDENTIAL [AOAICred]
--WITH IDENTITY = 'HTTPEndpointHeaders',
--SECRET = '{"api-key": "731b1db14f094ec8ad70e7dee12d1bc4"}';

CREATE DATABASE SCOPED CREDENTIAL [MyAOAICredential]
WITH IDENTITY = 'HTTPEndpointHeaders',
SECRET = '{"api-key": "731b1db14f094ec8ad70e7dee12d1bc4"}'; -- Replace with your actual Azure OpenAI API key

--ALTER DATABASE SCOPED CREDENTIAL [MyAOAICredential]
--WITH IDENTITY = 'HTTPEndpointAuthentication',
--SECRET = '{"Authentication":"ApiKey", "ApiKey": "731b1db14f094ec8ad70e7dee12d1bc4"}';

-- Step 2: Register the External Model using the credential
CREATE EXTERNAL MODEL [MyAOAI]
WITH (
    LOCATION   = 'https://cosmicgbb-openai.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-05-15', -- Replace with your deployment name
    API_FORMAT = 'AZURE OPENAI',
    MODEL      = 'text-embedding-ada-002',  -- Replace with your actual model name
    MODEL_TYPE = EMBEDDINGS,
    CREDENTIAL = [MyAOAICredential]
);

--ALTER EXTERNAL MODEL [MyAOAI]
--SET (
--    LOCATION   = 'https://cosmicgbb-openai.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-05-15', -- Replace with your deployment name
--    API_FORMAT = 'AZURE OPENAI',
--    MODEL      = 'text-embedding-ada-002',  -- Replace with your actual model name
--    MODEL_TYPE = EMBEDDINGS,
--    CREDENTIAL = MyAOAICredential
--);


-- Step 1: Create new table in current database (master) for demo
CREATE TABLE [dbo].[PersonEmbeddings] (
    [BusinessEntityID] INT PRIMARY KEY,
    [FirstName] NVARCHAR(50),
    [LastName] NVARCHAR(50),
    [FullName] AS ([FirstName] + N' ' + [LastName]),
    [Embedding] VECTOR(1536) -- Adjust dimension as per model
);

-- Step 2: Insert sample data from AdventureWorks (assuming linked server or three-part name)
INSERT INTO [dbo].[PersonEmbeddings] ([BusinessEntityID], [FirstName], [LastName])
SELECT TOP (100)
    [BusinessEntityID], [FirstName], [LastName]
FROM [AdventureWorks].[Person].[Person];

SELECT TOP 100
    'INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (' +
    CAST(CustomerID AS VARCHAR(10)) + ', ' +
    '''' + REPLACE(FirstName, '''', '''''') + ''', ' +
    '''' + REPLACE(LastName, '''', '''''') + ''');'
AS InsertCommand
FROM [SalesLT].[Customer];


SELECT * FROM PersonEmbeddings;

select * 
from sys.system_internals_allocation_units as IAU
inner join sys.system_internals_partitions as SIP
on IAU.container_id = SIP.partition_id
where sip.object_id = object_id('PersonEmbeddings')

--allocation_unit_id	type	type_desc	container_id	filegroup_id	total_pages	used_pages	data_pages	first_page	root_page	first_iam_page	partition_id	object_id	index_id	partition_number	rows	filestream_filegroup_id	is_orphaned	dropped_lob_column_state	is_unique
--72057594076921856	1	IN_ROW_DATA	72057594067091456	1	9	2	1	0xF86A00000100	0xF86A00000100	0x206C00000100	72057594067091456	1335675806	1	1	100	0	0	2	1

DBCC TRACEON(3604)
DBCC PAGE(AdventureWorks, 1, 27384,3)

/*
Slot 0 Offset 0x140 Length 59

Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS VERSIONING_INFO
Record Size = 59                    
Memory Dump @0x0000005909FF8140

0000000000000000:   70000800 26000000 04000802 0017002d 004b0069  p...&..........-.K.i
0000000000000014:   006d0041 00620065 00720063 0072006f 006d0062  .m.A.b.e.r.c.r.o.m.b
0000000000000028:   00690065 00000000 00000000 008a4700 000000    .i.e.........G....

Version Information = 
	Transaction Timestamp: 18314
	Version Pointer: Null


Slot 0 Column 1 Offset 0x4 Length 4 Length (physical) 4

BusinessEntityID = 38               

Slot 0 Column 2 Offset 0x11 Length 6 Length (physical) 6

FirstName = Kim                     

Slot 0 Column 3 Offset 0x17 Length 22 Length (physical) 22

LastName = Abercrombie              

Slot 0 Column 5 Offset 0x0 Length 0 Length (physical) 0

Embedding = [NULL]                  

Slot 0 Offset 0x0 Length 0 Length (physical) 0

KeyHashValue = (a8fc9de67ccb)       
Slot 1 Offset 0xba2 Length 47
*/

-- Step 3: Generate embeddings for FullName and store in Embedding column
UPDATE [dbo].[PersonEmbeddings]
SET [Embedding] = CAST(
    AI_GENERATE_EMBEDDINGS([FullName] USE MODEL MyAOAI) AS VECTOR(1536)
);

EXEC sp_configure 'external rest endpoint enabled',1
RECONFIGURE;

UPDATE [dbo].[PersonEmbeddings]
SET [Embedding] = CAST(
    AI_GENERATE_EMBEDDINGS([FullName] USE MODEL MyAOAI) AS VECTOR(1536)
);

select * from sys.databases

alter database current set compatibility_level = 170
go

SELECT * FROM sys.external_models

SP_CONFIGURE 'EX'

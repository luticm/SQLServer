CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd.azuresql';

CREATE DATABASE SCOPED CREDENTIAL [MyAOAICredential]
WITH IDENTITY = 'HTTPEndpointHeaders',
SECRET = '{"api-key": "731b1db14f094ec8ad70e7dee12d1bc4"}'; -- Replace with your actual Azure OpenAI API key

CREATE EXTERNAL MODEL [MyAOAI]
WITH (
    LOCATION   = 'https://cosmicgbb-openai.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-05-15', -- Replace with your deployment name
    API_FORMAT = 'AZURE OPENAI',
    MODEL      = 'text-embedding-ada-002',  -- Replace with your actual model name
    MODEL_TYPE = EMBEDDINGS,
    CREDENTIAL = [MyAOAICredential]
);

CREATE TABLE [dbo].[PersonEmbeddings] (
    [BusinessEntityID] INT PRIMARY KEY,
    [FirstName] NVARCHAR(50),
    [LastName] NVARCHAR(50),
    [FullName] AS ([FirstName] + N' ' + [LastName]),
    [Embedding] VECTOR(1536) -- Adjust dimension as per model
);

INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (1, 'Orlando', 'Gee');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (2, 'Keith', 'Harris');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (3, 'Donna', 'Carreras');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (4, 'Janet', 'Gates');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (5, 'Lucy', 'Harrington');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (6, 'Rosmarie', 'Carroll');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (7, 'Dominic', 'Gash');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (10, 'Kathleen', 'Garza');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (11, 'Katherine', 'Harding');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (12, 'Johnny', 'Caprio');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (16, 'Christopher', 'Beck');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (18, 'David', 'Liu');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (19, 'John', 'Beaver');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (20, 'Jean', 'Handley');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (21, 'Jinghao', 'Liu');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (22, 'Linda', 'Burnett');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (23, 'Kerim', 'Hanif');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (24, 'Kevin', 'Liu');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (25, 'Donald', 'Blanton');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (28, 'Jackie', 'Blackwell');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (29, 'Bryan', 'Hamilton');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (30, 'Todd', 'Logan');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (34, 'Barbara', 'German');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (37, 'Jim', 'Geist');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (38, 'Betty', 'Haines');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (39, 'Sharon', 'Looney');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (40, 'Darren', 'Gehring');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (41, 'Erin', 'Hagens');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (42, 'Jeremy', 'Los');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (43, 'Elsa', 'Leavitt');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (46, 'David', 'Lawrence');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (47, 'Hattie', 'Haemon');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (48, 'Anita', 'Lucerne');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (52, 'Rebecca', 'Laszlo');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (55, 'Eric', 'Lang');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (56, 'Brian', 'Groth');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (57, 'Judy', 'Lundahl');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (58, 'Peter', 'Kurniawan');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (59, 'Douglas', 'Groncki');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (60, 'Sean', 'Lunt');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (61, 'Jeffrey', 'Kurtz');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (64, 'Vamsi', 'Kuppa');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (65, 'Jane', 'Greer');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (66, 'Alexander', 'Deborde');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (70, 'Deepak', 'Kumar');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (73, 'Margaret', 'Krupka');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (74, 'Christopher', 'Bright');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (75, 'Aidan', 'Delaney');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (76, 'James', 'Krow');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (77, 'Michael', 'Brundage');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (78, 'Stefan', 'Delmarco');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (79, 'Mitch', 'Kennedy');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (82, 'James', 'Kramer');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (83, 'Eric', 'Brumfield');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (84, 'Della', 'Demott Jr');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (88, 'Pamala', 'Kotc');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (91, 'Joy', 'Koski');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (92, 'Jovita', 'Carmody');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (93, 'Prashanth', 'Desai');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (94, 'Scott', 'Konersmann');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (95, 'Jane', 'Carmichael');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (96, 'Bonnie', 'Lepro');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (97, 'Eugene', 'Kogan');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (100, 'Kirk', 'King');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (101, 'William', 'Conner');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (102, 'Linda', 'Leste');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (106, 'Andrea', 'Thomsen');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (109, 'Daniel', 'Thompson');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (110, 'Kendra', 'Thompson');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (111, 'Scott', 'Colvin');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (112, 'Elsie', 'Lewin');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (113, 'Donald', 'Thompson');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (114, 'John', 'Colon');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (115, 'George', 'Li');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (118, 'Yale', 'Li');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (119, 'Phyllis', 'Thomas');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (120, 'Pat', 'Coleman');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (124, 'Yuhong', 'Li');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (127, 'Joseph', 'Lique');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (128, 'Judy', 'Thames');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (129, 'Connie', 'Coffman');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (130, 'Paulo', 'Lisboa');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (131, 'Vanessa', 'Tench');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (132, 'Teanna', 'Cobb');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (133, 'Michael', 'Graff');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (136, 'Derek', 'Graham');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (137, 'Gytis', 'Barzdukas');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (138, 'Jane', 'Clayton');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (142, 'Jon', 'Grande');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (145, 'Ted', 'Bremer');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (146, 'Richard', 'Bready');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (147, 'Alice', 'Clark');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (148, 'Alan', 'Brewer');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (149, 'Cornelius', 'Brandon');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (150, 'Jill', 'Christie');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (151, 'Walter', 'Brian');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (154, 'Carlton', 'Carlisle');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (155, 'Joseph', 'Castellucio');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (156, 'Lester', 'Bowman');
INSERT INTO [dbo].[PersonEmbeddings] (BusinessEntityID, FirstName, LastName) VALUES (160, 'Brigid', 'Cavendish');
GO

SELECT * FROM SYS.databases
SELECT object_id('PersonEmbeddings')

DBCC EXTENTINFO(5, 1458104235, -1)
GO

select * 
from sys.system_internals_allocation_units as IAU
inner join sys.system_internals_partitions as SIP
on IAU.container_id = SIP.partition_id
where sip.object_id = object_id('PersonEmbeddings')

--allocation_unit_id	type	type_desc	container_id	filegroup_id	total_pages	used_pages	data_pages	first_page	root_page	first_iam_page	partition_id	object_id	index_id	partition_number	rows	filestream_filegroup_id	is_orphaned	dropped_lob_column_state	is_unique
--72057594076921856	1	IN_ROW_DATA	72057594067091456	1	9	2	1	0xF86A00000100	0xF86A00000100	0x206C00000100	72057594067091456	1335675806	1	1	100	0	0	2	1

DBCC TRACEON(3604)
DBCC PAGE(AdventureWorks, 1, 27384,3)


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
WHERE t.name = 'PersonEmbeddings';

UPDATE [dbo].[PersonEmbeddings]
SET [Embedding] = CAST(
    AI_GENERATE_EMBEDDINGS([FullName] USE MODEL MyAOAI) AS VECTOR(1536)
);
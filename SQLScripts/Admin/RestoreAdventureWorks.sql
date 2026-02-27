RESTORE FILELISTONLY 
FROM DISK = 'C:\Files\Projects\Datasets\Databases\AdventureWorks2022.bak'

RESTORE FILELISTONLY
FROM DISK = 'C:\Files\Projects\Datasets\Databases\AdventureWorksDW2022.bak';

RESTORE FILELISTONLY
FROM DISK = 'C:\Files\Projects\Datasets\Databases\AdventureWorksLT2022.bak';

RESTORE DATABASE AdventureWorks
FROM DISK = 'C:\Files\Projects\Datasets\Databases\AdventureWorks2022.bak'
WITH 
	MOVE 'AdventureWorks2022' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.INST2025\MSSQL\DATA\AdventureWorks2022.mdf',
	MOVE 'AdventureWorks2022_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.INST2025\MSSQL\DATA\AdventureWorks2022.ldf';

RESTORE DATABASE AdventureWorksDW
FROM DISK = 'C:\Files\Projects\Datasets\Databases\AdventureWorksDW2022.bak'
WITH 
	MOVE 'AdventureWorksDW2022' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.INST2025\MSSQL\DATA\AdventureWorksDW2022.mdf',
	MOVE 'AdventureWorksDW2022_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.INST2025\MSSQL\DATA\AdventureWorksDW2022.ldf';

RESTORE DATABASE AdventureWorksLT
FROM DISK = 'C:\Files\Projects\Datasets\Databases\AdventureWorksLT2022.bak'
WITH 
	MOVE 'AdventureWorksLT2022_Data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.INST2025\MSSQL\DATA\AdventureWorksLT2022.mdf',
	MOVE 'AdventureWorksLT2022_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.INST2025\MSSQL\DATA\AdventureWorksLT2022.ldf';

-- RESTORE DATABASE AdventureWorksBig
-- FROM DISK = 'C:\Files\Projects\Datasets\Databases\AdventureWorks2022.bak'
-- WITH 
-- 	MOVE 'AdventureWorks2022' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorks2022_Big.mdf',
-- 	MOVE 'AdventureWorks2022_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorks2022_Big.ldf'
-- 	, STATS=5


-- DROP DATABASE AdventureWorks;

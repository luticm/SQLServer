/****************************************************************************************
*****************************************************************************************
			 
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 02 - Demo 03 - Backup compression e memória
	Descrição: 
		
	* Copyright (C) 2012 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

SELECT * FROM SYS.DATABASES

-- MemUsage database DBID = 16
DBCC DROPCLEANBUFFERS()
GO

BACKUP DATABASE MemUsage
TO DISK = 'C:\TEMP\MemUsage.bak'
WITH INIT, FORMAT
go

-- Em outra sessão
DECLARE @I INT = 0
WHILE @I < 20
BEGIN
	PRINT CONVERT(VARCHAR(50), GETDATE(), 121)
	SELECT *
	FROM sys.dm_os_memory_clerks
	WHERE type like 'MEMORYCLERK_SQLUTILITIES'

	SET @I = @I + 1
	WAITFOR DELAY '00:00:00.500' 	
END

DBCC DROPCLEANBUFFERS()
GO

-- Com compressão... Qual a diferença de tempo? E o motivo?
BACKUP DATABASE MemUsage
TO DISK = 'C:\TEMP\MemUsage.bak'
WITH COMPRESSION, INIT, FORMAT
go

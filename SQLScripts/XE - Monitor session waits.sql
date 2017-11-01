/****************************************************************************************
*****************************************************************************************

	Author: Luciano Caixeta Moreira
	E-mail: luticm79@hotmail.com
	LinkedIn: http://www.linkedin.com/in/luticm
	Blog: http://blogs.msdn.microsoft.com/luti / http://luticm.blogspot.com
	Twitter: @luticm
	
	Title: XE to collect waits from a specific session
	Description: 

	History (yyyy-mm-dd):
		- 2017-04-27: Publishing draft version


		THIS SOFTWARE IS PROVIDED 'AS-IS', WITHOUT ANY EXPRESS OR IMPLIED
		WARRANTY.  IN NO EVENT WILL THE AUTHORS BE HELD LIABLE FOR ANY DAMAGES
		ARISING FROM THE USE OF THIS SOFTWARE.
	
*****************************************************************************************	
****************************************************************************************/

USE master
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'MonitorWaits')
    DROP EVENT SESSION MonitorWaits ON SERVER
GO

-- !!! Need to define the SESSION ID that will be monitored
CREATE EVENT SESSION MonitorWaits ON SERVER
ADD EVENT sqlos.wait_info
    (WHERE sqlserver.session_id = 54)
ADD TARGET package0.asynchronous_file_target
    (SET FILENAME = N'C:\Temp\EE_WaitStats.xel')
WITH (max_dispatch_latency = 1 seconds);
GO

-- Start the session
ALTER EVENT SESSION MonitorWaits ON SERVER STATE = START;
GO

--  !!! Execute query !!!

ALTER EVENT SESSION MonitorWaits ON SERVER STATE = STOP;
GO

USE tempdb
GO

-- Checking number of events collect
SELECT COUNT (*)
FROM sys.fn_xe_file_target_read_file(N'C:\Temp\EE_WaitStats*.xel', NULL, null, null);

-- Create temporaty table to load data
CREATE TABLE #RawEventData (
    Rowid  INT IDENTITY PRIMARY KEY,
    event_data XML);
GO

INSERT INTO #RawEventData (event_data)
SELECT
    CAST (event_data AS XML) AS event_data
FROM sys.fn_xe_file_target_read_file ( N'C:\Temp\EE_WaitStats*.xel', NULL, null, null);

-- Checking waits
SELECT
    waits.[Wait Type],
    COUNT (*) AS [Wait Count],
    SUM (waits.[Duration]) AS [Total Wait Time (ms)],
    SUM (waits.[Duration]) - SUM (waits.[Signal Duration]) AS [Total Resource Wait Time (ms)],
    SUM (waits.[Signal Duration]) AS [Total Signal Wait Time (ms)]
FROM
    (SELECT
        event_data.value ('(/event/@timestamp)[1]', 'DATETIME') AS [Time],
        event_data.value ('(/event/data[@name=''wait_type'']/text)[1]', 'VARCHAR(100)') AS [Wait Type],
        event_data.value ('(/event/data[@name=''opcode'']/text)[1]', 'VARCHAR(100)') AS [Op],
        event_data.value ('(/event/data[@name=''duration'']/value)[1]', 'BIGINT') AS [Duration],
        event_data.value ('(/event/data[@name=''signal_duration'']/value)[1]', 'BIGINT') AS [Signal Duration]
     FROM #RawEventData
    ) AS waits
WHERE waits.[op] = 'End'
GROUP BY waits.[Wait Type]
ORDER BY [Total Wait Time (ms)] DESC;
GO 
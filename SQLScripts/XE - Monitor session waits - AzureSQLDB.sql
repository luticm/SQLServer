/****************************************************************************************
*****************************************************************************************

	Author: Luciano Caixeta Moreira
	E-mail: luticm79@hotmail.com / luciano.moreira@microsoft.com
	LinkedIn: http://www.linkedin.com/in/luticm
	Twitter: @luticm
	
	Title: XE to collect waits from a specific session in Azure SQL DB
	Description: 

	History (yyyy-mm-dd):
		- 2022-04-29: Adjusting for Azure SQL DB using ring buffer

    THIS SOFTWARE IS PROVIDED 'AS-IS', WITHOUT ANY EXPRESS OR IMPLIED
    WARRANTY.  IN NO EVENT WILL THE AUTHORS BE HELD LIABLE FOR ANY DAMAGES
    ARISING FROM THE USE OF THIS SOFTWARE.
	
*****************************************************************************************	
****************************************************************************************/

/*
select * from sys.dm_xe_database_session_events;
select * from sys.dm_xe_database_session_event_actions;
select * from sys.dm_xe_database_session_object_columns;
select * from sys.dm_xe_database_session_targets;
select * from sys.database_event_sessions;
*/

IF EXISTS (SELECT * FROM sys.database_event_sessions WHERE name = 'MonitorSessionWaits')
    DROP EVENT SESSION MonitorSessionWaits ON DATABASE
GO

-- !!! Need to define the SESSION ID that will be monitored
CREATE EVENT SESSION MonitorSessionWaits 
ON DATABASE
ADD EVENT sqlos.wait_info
    (WHERE sqlserver.session_id = 76)
ADD TARGET package0.ring_buffer
WITH (max_memory = 10 MB ); 
GO

-- Start the session
ALTER EVENT SESSION MonitorSessionWaits ON DATABASE STATE = START;
GO

--  !!! Let it rip in the other session !!!

CREATE TABLE #RawEventData (
    Rowid  INT IDENTITY PRIMARY KEY,
    event_data XML);
GO

DELETE FROM #RawEventData

INSERT INTO #RawEventData (event_data)
SELECT
    CAST (XDST.target_data AS XML) AS event_data
FROM sys.dm_xe_database_session_events AS XDSE
INNER JOIN sys.dm_xe_database_session_targets AS XDST
         ON CAST(XDST.event_session_address AS BINARY(8)) = CAST(XDSE.event_session_address AS BINARY(8))

-- SELECT * FROM #RawEventData

SELECT
    waits.wait_type,
    COUNT (*) AS [Wait Count],
    SUM (waits.wait_type_duration_ms) AS [Total Wait Time (ms)],
    SUM (waits.wait_type_duration_ms) - SUM (waits.wait_type_signal_duration_ms) AS [Total Resource Wait Time (ms)],
    SUM (waits.wait_type_signal_duration_ms) AS [Total Signal Wait Time (ms)]
FROM
    (SELECT
		--XED.event_data.value('/', 'VARCHAR(8000)') AS T,
		XED.event_data.value('(@timestamp)[1]', 'datetime2') AS [timestamp],
		xed.event_data.value('(data[@name="wait_type"]/text)[1]', 'varchar(50)') AS wait_type,
		xed.event_data.value('(data[@name="opcode"]/text)[1]', 'varchar(50)') AS OpCode, 
		xed.event_data.value('(data[@name="duration"]/value)[1]', 'int') AS wait_type_duration_ms, 
		xed.event_data.value('(data[@name="signal_duration"]/value)[1]', 'int') AS wait_type_signal_duration_ms 
     FROM #RawEventData
	 CROSS APPLY event_data.nodes('//RingBufferTarget/event') AS XED(event_data)
    ) AS waits
WHERE waits.OpCode = 'End'
GROUP BY waits.wait_type
ORDER BY [Total Wait Time (ms)] DESC;
GO 

ALTER EVENT SESSION MonitorSessionWaits ON DATABASE STATE = STOP;
GO

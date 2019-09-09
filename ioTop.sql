DECLARE @SystemIO FLOAT
SELECT @SystemIO = SUM(total_logical_reads + total_logical_writes)
FROM sys.dm_exec_query_stats;
 
SELECT TOP 20 [Row Number] = ROW_NUMBER() OVER (ORDER BY total_logical_reads + total_logical_writes DESC),
    [Query Text] = CASE
        WHEN [sql_handle] IS NULL THEN ' '
        ELSE (SUBSTRING(ST.TEXT,(QS.statement_start_offset + 2) / 2,
            (CASE
                WHEN QS.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),ST.text)) * 2
                ELSE QS.statement_end_offset
                END - QS.statement_start_offset) / 2))
        END,
    [Execution Count] = execution_count,
    [Total IO] = total_logical_reads + total_logical_writes,
    [Average IO] = (total_logical_reads + total_logical_writes) / (execution_count + 0.0),
    [System Percentage] = 100 * (total_logical_reads + total_logical_writes) / @SystemIO,
    [Object Name] = OBJECT_NAME(ST.objectid),
    [Total System IO] = @SystemIO,
    [SQL Handle] = [sql_handle]
FROM sys.dm_exec_query_stats QS
CROSS APPLY sys.dm_exec_sql_text ([sql_handle]) ST
WHERE total_logical_reads + total_logical_writes > 0
ORDER BY [Total IO] DESC
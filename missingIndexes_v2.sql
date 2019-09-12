SELECT DB_NAME(d.database_id) AS DBNAME,
      d.statement AS [ObjectName],
       gs.unique_compiles, 
       gs.user_seeks, 
       gs.user_scans, 
       gs.avg_total_user_cost, 
       gs.avg_user_impact, 
       'CREATE INDEX MissingIndex_' + rtrim(cast(d.index_handle AS char(100))) + 
       ' ON ' + d.statement + ' (' +  
       CASE WHEN equality_columns IS NOT NULL THEN equality_columns  ELSE '' END + 
       CASE WHEN equality_columns IS NOT NULL AND 
                 inequality_columns IS NOT NULL THEN ', ' ELSE '' END + 
       CASE WHEN inequality_columns IS NOT NULL THEN inequality_columns ELSE '' END + ') ' +
       CASE WHEN included_columns IS NOT NULL THEN 'INCLUDE (' + included_columns + ')' ELSE '' END AS MissingIndex  
FROM sys.dm_db_missing_index_groups g
	join sys.dm_db_missing_index_group_stats gs ON gs.group_handle = g.index_group_handle
	join sys.dm_db_missing_index_details d ON g.index_handle = d.index_handle 
--WHERE DB_NAME(d.database_id) = 'TUI'
ORDER BY gs.user_scans, gs.user_seeks DESC;


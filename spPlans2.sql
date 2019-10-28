select name, usecounts, query_plan
FROM sys.dm_exec_cached_plans AS ecp 
CROSS APPLY sys.dm_exec_query_plan(ecp.plan_handle) AS eqp 
join sys.objects as o on o.object_id = eqp.objectid
where ecp.objtype = 'Proc'
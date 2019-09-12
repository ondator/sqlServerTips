SET  QUOTED_IDENTIFIER ON
WITH XMLNAMESPACES   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
SELECT   
 query_plan AS CompleteQueryPlan
,t.text
,n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') AS StatementOptimizationLevel
,ecp.usecounts,      ecp.size_in_bytes ,ecp.objtype
FROM sys.dm_exec_cached_plans AS ecp 
CROSS APPLY sys.dm_exec_query_plan(ecp.plan_handle) AS eqp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n) 
cross apply sys.dm_exec_sql_text (ecp.plan_handle) AS t
WHERE  objtype = 'Adhoc' and cacheobjtype = 'Compiled Plan'
and usecounts = 1 
and n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') is not null 
and text not like '%sys.dm%'
order by  ecp.size_in_bytes  desc


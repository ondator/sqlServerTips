with cte as ( select
                     er.session_id as session_id1
                     
                    ,OBJECT_SCHEMA_NAME(st.objectid ,st.dbid) + '.' + 
                     object_name(st.objectid ,st.dbid) as ObjectName
                    ,substring( st.text
                      ,(er.statement_start_offset / 2) + 1
                      ,( ( case er.statement_end_offset
                             when -1 then datalength(st.text)
                             else er.statement_end_offset
                           end - er.statement_start_offset) / 2) + 1) as statement_text
                    ,s.cpu_time        as s_cpu_time
                    ,s.reads           as s_reads
                    ,s.writes          as s_writes
                    ,s.logical_reads   as s_logical_reads
                    ,er.cpu_time       as r_cpu_time
                    ,er.reads          as r_reads
                    ,er.writes         as r_writes
                    ,er.logical_reads  as r_logical_reads
                    ,qp.query_plan
                    ,db_name(st.dbid) as [dbID1]
                    ,blocking_session_id as blocking_session_id1 
                    ,--'kill '+ convert(varchar(5),er.session_id),
                     last_wait_type as last_wait_type1
                    ,wait_resource as wait_resource1
                    ,s.last_request_start_time
                    ,s.last_request_end_time
                    ,s.host_name
                    ,s.login_name
                    ,s.original_login_name
                    ,s.program_name
                    ,er.*
                     
                    --,st.*
                    --,s.*
                from sys.dm_exec_requests as er
                cross apply sys.dm_exec_sql_text(er.sql_handle) as st
              join sys.dm_exec_sessions s on s.session_id = er.session_id
                cross apply sys.dm_exec_query_plan(er.plan_handle) as qp  
                where er.session_id <> @@SPID --and st.text not like 'WAITFOR (RECEIVE message_id, message_body, status, queuing_order, conversation_group_id, conversation_handle, message_sequence_number, service_contract_name, service_contract_id, message_type_name, message_type_id, validation %'
                                              --and login_name='ozon\bkomarov'
                                              --and er.session_id<>98
                                              --order by 2,1,  3
                      )
 
select
       *
  from cte as c  
order by c.granted_query_memory desc
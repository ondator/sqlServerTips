select
db_name(database_id) DB,
OBJECT_SCHEMA_NAME (s.object_id) Sch,
object_name(s.object_id) Obj,
row_lock_count + page_lock_count No_Of_Locks,
row_lock_wait_count + page_lock_wait_count No_Of_Blocks,
row_lock_wait_in_ms + page_lock_wait_in_ms Block_Wait_Time,
s.index_id,
i.name
from sys.dm_db_index_operational_stats(NULL,NULL,NULL,NULL) as s
join sys.indexes as i on i.index_id = s.index_id and s.object_id = i.object_id
order by Block_Wait_Time desc
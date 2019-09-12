declare @dbid int
--To get Datbase ID
set @dbid = db_id()


select 
db_name(d.database_id) database_name
,object_name(d.object_id) object_name
,s.name index_name,
c.index_columns
,d.*
from sys.dm_db_index_usage_stats d
inner join sys.indexes  s
on d.object_id = s.object_id
and d.index_id = s.index_id
left outer join 
(select distinct object_id, index_id, 
stuff((SELECT   ','+col_name(object_id,column_id ) as 'data()' FROM sys.index_columns t2  where t1.object_id =t2.object_id  and t1.index_id = t2.index_id FOR XML PATH ('')),1,1,'')    
as 'index_columns' FROM  sys.index_columns t1  ) c on
c.index_id = s.index_id and c.object_id = s.object_id
where database_id = @dbid
and objectproperty(d.object_id, 'IsIndexable') = 1
and object_name(d.object_id) = 'Area'
order by 
(user_seeks+user_scans+user_lookups+system_seeks+system_scans+system_lookups) desc
go



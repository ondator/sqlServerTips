select o.name, * from sys.dm_tran_locks  as l
join sys.objects as o on o.object_id = l.resource_associated_entity_id
where resource_type = 'OBJECT'
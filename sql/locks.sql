select
  object_name, 
  object_type, 
  session_id, 
  type, 		-- Type or system/user lock
  lmode,    	-- lock mode in which session holds lock
  request, 
  block, 
  ctime 		-- Time since current mode was granted
from
  v$locked_object, all_objects, v$lock
where
  v$locked_object.object_id = all_objects.object_id AND
  v$lock.id1 = all_objects.object_id AND
  v$lock.sid = v$locked_object.session_id
order by
  session_id, ctime desc, object_name
/

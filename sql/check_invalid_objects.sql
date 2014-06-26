set pagesize 999
set linesize 1000
set trimspool on
select 
   owner       , 
   object_type ,
   object_name 
from 
   dba_objects 
where 
   status != 'VALID'
order by
   owner,
   object_type
;


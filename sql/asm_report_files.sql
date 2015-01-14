set pagesize 9999
set linesize 9999
column full_alias_path format a80
column file_type format a25
column USED_MB format 999,990
column ALLOC_MB format 999,990
ALTER SESSION SET NLS_DATE_FORMAT ='YYYY-MM-DD';
 

select concat('+'||gname, sys_connect_by_path(aname, '/')) full_alias_path
, block_size
, blocks
, bytes/1024/1024 as USED_MB
, space/1024/1024 as ALLOC_MB
,system_created
,alias_directory
,file_type
,redundancy
,creation_date as create_dt
,modification_date as modify_dt
from ( 
select 
b.name gname
, a.parent_index pindex
, a.name aname 
, c.block_size
, c.blocks
, c.bytes
, c.space
, c.redundancy
, c.creation_date
, c.modification_date
, a.reference_index rindex 
, a.system_created
, a.alias_directory
, c.type file_type
from v$asm_alias a, v$asm_diskgroup b, v$asm_file c
where a.group_number = b.group_number
and a.group_number = c.group_number(+)
and a.file_number = c.file_number(+)
and a.file_incarnation = c.incarnation(+)
)
start with (mod(pindex, power(2, 24))) = 0
            and rindex in 
                ( select a.reference_index
                  from v$asm_alias a, v$asm_diskgroup b
                  where a.group_number = b.group_number
                        and (mod(a.parent_index, power(2, 24))) = 0
                )
connect by prior rindex = pindex
order by full_alias_path asc;

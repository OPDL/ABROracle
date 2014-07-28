col tablespace_name format a30
col file_name format a60
col autoextensible format a3
col MB format 9999999.99
col MaxMB format 9999999.99
set lines 200
select tablespace_name,file_name,bytes/(1024*1024) MB, autoextensible, maxbytes/(1024*1024) MaxMB
from dba_data_files where tablespace_name in
(select upper(value) from gv$parameter where name='undo_tablespace')
order by tablespace_name;

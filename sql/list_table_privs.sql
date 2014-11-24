set pagesize 9999
set linesize 9999
set trimspool on

spool tab_privs.txt
SET TERMOUT OFF
SELECT grantee, owner, table_name, privilege FROM sys.dba_tab_privs WHERE grantee='PUBLIC'
and owner not in ('SYS')
;
SET TERMOUT ON
spool off


set VER off
set HEA off
set FEED off
set linesize 140
set pagesize 100
spool dbv.cmd
 select 'dbv userid=system/PASSWORD file=' || FILE_NAME ||
        ' feedback=100 '   || ' &>' || FILE_ID || '_' || sysdate || '_dbv_output'
from dba_data_files;
spool off
host chmod 770 dbv.cmd
set FEED on
set VER on
set HEA on

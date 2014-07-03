SET NEWPAGE 0
SET SPACE 2
SET PAGESIZE 50
SET LINESIZE 9999
SET ECHO OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET MARKUP HTML OFF SPOOL OFF
COLUMN MAX_USED% HEAD 'MAX|USED%' FORMAT 99
COLUMN ALLOC_USED% HEAD 'ALLOC|USED%' FORMAT 99
COLUMN MAXGROWTHMB HEAD 'MAXGROWTH|MB' FORMAT 999999
COLUMN USEDMB FORMAT 999999
COLUMN FREEMB FORMAT 999999
COLUMN SIZEMB FORMAT 999999
COLUMN MAXSIZEMB FORMAT 999999
select
CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(20)) as "HOST",
CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "SID",
b.TYPE,
b.tablespace_name,
round(DECODE(max_tbs_size,0,null,round(100*(tbs_size - a.free_space)/max_tbs_size,2)),2) "MAX_USED%",
round(100*(tbs_size - a.free_space)/tbs_size,2) "ALLOC_USED%",
autoextensible as ae,
status,
max_tbs_size MAXSIZEMB,
tbs_size SIZEMB,
a.free_space FREEMB,
(tbs_size - a.free_space) USEDMB,
CASE WHEN round(max_tbs_size-tbs_size,2) < 0 THEN 0 ELSE round(max_tbs_size-tbs_size,2) END MAXGROWTHMB
from
(
select tablespace_name, 'DATA' as "TYPE",round(sum(bytes)/1024/1024 ,2) as free_space
from dba_free_space group by tablespace_name
) a,
(
select
tablespace_name,autoextensible,online_status as status,
'DATA' as "TYPE",
round(sum(bytes)/1024/1024,2) as tbs_size ,
round(sum(maxbytes)/1024/1024,2) as max_tbs_size
from dba_data_files group by tablespace_name,autoextensible,online_status
UNION
select
tablespace_name,autoextensible,status,
'TEMP' as "TYPE",
sum(bytes)/1024/1024 tbs_size,
null as max_tbs_size
from dba_temp_files
group by tablespace_name,autoextensible,status
) b
where a.tablespace_name(+)=b.tablespace_name
order by type,tablespace_name;


set linesize 200
set pagesize 999

col ACTION_TIME format a29
col VERSION format a20
col COMMENTS format a30
col ACTION for a16
col NAMESPACE format a8
col BUNDLE_SERIES format a6

select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,a.* from registry$history a order by 4 desc
;


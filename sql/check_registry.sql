set linesize 120
set pagesize 999

col ACTION_TIME format a29
col VERSION format a10
col COMMENTS format a30
col ACTION for a16
col NAMESPACE format a8
col BUNDLE_SERIES format a6

select * from registry$history order by 1
;


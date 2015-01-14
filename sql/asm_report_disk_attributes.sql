set pagesize 9999
set linesize 9999
col DISKGROUP format A15
col NAME format A45
SELECT dg.name AS diskgroup
,a.name as name
--, SUBSTR(a.name,1,18) AS name
,SUBSTR(a.value,1,24) AS value
,read_only as RO FROM V$ASM_DISKGROUP dg,
     V$ASM_ATTRIBUTE a WHERE
     dg.group_number = a.group_number
;


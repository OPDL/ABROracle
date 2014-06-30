select * from
(
select
CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(20)) as "HOST",
CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "SID"
FROM DUAL
) a
CROSS JOIN
(
select 
owner,
sum(space)/1024/1024 RECYCLEBIN_SIZEMB from dba_recyclebin group by owner order by owner
) b
;


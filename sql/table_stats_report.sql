select case nvl(last_analyzed,to_date('1/1/1970','mm/dd/yyyy')) when to_date('1/1/1970','mm/dd/yyyy') then '0' else '1' end as flag from dba_tables;

select username from dba_users
where username not in (select user_name from sys.DEFAULT_PWD$) and username not in ('ODMRSYS');

SELECT owner, table_name, TO_CHAR(last_analyzed, 'yyyy-mm-dd') as last_analyzed FROM dba_tables 
where owner not in (select user_name from sys.DEFAULT_PWD$) and owner not in ('ODMRSYS')
and last_analyzed is null

SELECT owner, index_name, index_type, table_name, TO_CHAR(last_analyzed, 'yyyy-mm-dd') as last_analyzed FROM dba_indexes 
where owner not in (select user_name from sys.DEFAULT_PWD$) and owner not in ('ODMRSYS')
and last_analyzed is null


SELECT owner, table_name, TO_CHAR(last_analyzed, 'yyyy-mm-dd') as last_analyzed FROM dba_tables 
where owner not in (select user_name from sys.DEFAULT_PWD$) and owner not in ('ODMRSYS')


SELECT owner, table_name, stale_stats, TO_CHAR(last_analyzed, 'yyyy-mm-dd') as last_analyzed FROM dba_tab_statistics
where owner not in (select user_name from sys.DEFAULT_PWD$) and owner not in ('ODMRSYS')
and stale_stats='YES'
SELECT owner, index_name, table_name, stale_stats, TO_CHAR(last_analyzed, 'yyyy-mm-dd') as last_analyzed FROM dba_ind_statistics
where owner not in (select user_name from sys.DEFAULT_PWD$) and owner not in ('ODMRSYS')
and stale_stats='YES'

SELECT table_owner, table_name, TO_CHAR(timestamp, 'yyyy-mm-dd hh:mi:ss am') as last_modified FROM  ALL_TAB_MODIFICATIONS
where table_owner not in (select user_name from sys.DEFAULT_PWD$) and table_owner not in ('ODMRSYS')


SELECT a.owner, a.table_name, a.stale_stats, TO_CHAR(a.last_analyzed, 'yyyy-mm-dd hh:mi:ss am') as last_analyzed, TO_CHAR(b.timestamp, 'yyyy-mm-dd hh:mi:ss am') as last_modified FROM dba_tab_statistics a, ALL_TAB_MODIFICATIONS b
where a.owner(+)=b.table_owner and a.table_name=b.table_name and a.owner not in (select user_name from sys.DEFAULT_PWD$) and a.owner not in ('ODMRSYS')



set linesize 9999
set pagesize 9999
SELECT a.owner, a.table_name,  b.stale_stats, TO_CHAR(a.last_analyzed, 'yyyy-mm-dd hh:mi:ss am') as last_analyzed ,TO_CHAR(c.timestamp, 'yyyy-mm-dd hh:mi:ss am') as last_modified
FROM dba_tables a, dba_tab_statistics b, ALL_TAB_MODIFICATIONS c
where
a.owner=b.owner and a.table_name=b.table_name
and
a.owner(+)=c.table_owner and a.table_name(+)=c.table_name 
and
a.owner not in (select user_name from sys.DEFAULT_PWD$) and a.owner not in ('ODMRSYS')

-- Use the constant DBMS_STATS.AUTO_CASCADE to have Oracle determine whether index statistics are to be collected or not. This is the default.

set linesize 180
set pagesize 9999
select * from (
select a.*, TO_CHAR(b.timestamp, 'yyyy-mm-dd') as last_modified
--, trunc(b.timestamp)-trunc(a.last_analyzed) as  days 
from
(
SELECT cast(a.owner as varchar2(15)) as owner, a.table_name,  b.stale_stats, TO_CHAR(a.last_analyzed, 'yyyy-mm-dd') as last_analyzed 
FROM dba_tables a left outer join dba_tab_statistics b
on
a.owner=b.owner and a.table_name=b.table_name 
where
a.owner not in (select user_name from sys.DEFAULT_PWD$) and a.owner not in ('ODMRSYS')
) a left outer join ALL_TAB_MODIFICATIONS b
on 
a.owner=b.table_owner and a.table_name=b.table_name
) where stale_stats='YES'



set linesize 180
set pagesize 9999
SELECT cast(a.owner as varchar2(15)) as owner, a.index_name,a.table_name,  b.stale_stats, TO_CHAR(a.last_analyzed, 'yyyy-mm-dd') as last_analyzed 
FROM dba_indexes a left outer join dba_ind_statistics b
on
a.owner=b.owner and a.index_name=b.index_name 
where
a.owner not in (select user_name from sys.DEFAULT_PWD$) and a.owner not in ('ODMRSYS')

exec dbms_stats.gather_schema_stats(ownname => 'INFAPROD',cascade => TRUE,method_opt => 'FOR ALL COLUMNS SIZE AUTO' );

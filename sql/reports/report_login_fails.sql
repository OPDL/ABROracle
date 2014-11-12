set feedback off
set pagesize 9999
set linesize 9999
set colsep '|'
set feedback off
set verify off
column USERNAME format A22
column USERHOST format A20
column OS_USERNAME format A20
column ACCOUNT_STATUS format A20
column "DAY RANGE" format A15
column "LAST_FAILED_LOGIN" format A22
column PROFILE format A20
DEFINE DAY_RANGE=30
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT ='MM/DD/YYYY HH24:MI:SS TZR TZD';
ALTER SESSION SET NLS_DATE_FORMAT ='MM-DD-YYYY HH24:MI:SS';

-- last failed login by username
select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,'Last &DAY_RANGE Days' as "DAY RANGE"
,os_username, userhost, username,TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS') as "LAST_FAILED_LOGIN" , returncode from
(
SELECT os_username, userhost, username, timestamp, returncode, row_number() over (partition by username order by timestamp desc) as "RN"
from dba_audit_trail
where action_name = 'LOGON'
and TO_DATE(TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS'),'YYYY-MON-DD HH24:MI:SS') > SYSDATE - &DAY_RANGE
and returncode > 0
) a
where rn=1
order by timestamp desc;

--  counts for login fails over time period.  detect hacking attempts
select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,'Last &DAY_RANGE Days' as "DAY RANGE"
,os_username, userhost, username, returncode, "CNT" as "FAILED ATTEMPTS" from
(
SELECT os_username, userhost, username, returncode, count(*) as "CNT"
from dba_audit_trail
where action_name = 'LOGON'
and TO_DATE(TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS'),'YYYY-MON-DD HH24:MI:SS') > SYSDATE - &DAY_RANGE
and returncode > 0
group by os_username,userhost,username,returncode
) a
order by CNT desc,username asc
;


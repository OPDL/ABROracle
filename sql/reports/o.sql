set feedback off
set pagesize 9999
set linesize 9999
column USERNAME format A20
column ACCOUNT_STATUS format A20
column PROFILE format A20
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT ='MM/DD/YYYY HH24:MI:SS TZR TZD';
ALTER SESSION SET NLS_DATE_FORMAT ='MM-DD-YYYY HH24:MI:SS';

-- accounts expiring in 7 days
select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,USERNAME, ACCOUNT_STATUS, LOCK_DATE, EXPIRY_DATE
from DBA_USERS
where 
EXPIRY_DATE < SYSDATE + 7
AND
LOCK_DATE IS NULL
order by username asc;

select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,USERNAME, ACCOUNT_STATUS, LOCK_DATE, EXPIRY_DATE, PROFILE 
from DBA_USERS
order by username asc;

-- LAST SUCCESSFUL LOGIN
select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,username
,'NEVER_LOGGED_IN' as "STATUS" 
from 
dba_users where account_status='OPEN' and username 
not in ( select username from dba_audit_trail where action_name 
in ('LOGOFF','LOGON') and username is not null );

select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,username
,TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS') as "LAST_SUCCESSFUL_LOGIN" 
,returncode from
(
SELECT username, timestamp, returncode, max(TO_DATE (TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS'),'YYYY-MON-DD HH24:MI:SS')) over (partition by username) as max_ts
from dba_audit_trail
where action_name = 'LOGON'
and returncode = 0
) a
where timestamp = a.max_ts
order by LAST_SUCCESSFUL_LOGIN desc;


-- LAST FAILED LOGIN
select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,username
,TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS') as "LAST_FAILED_LOGIN" 
,returncode 
from
(
SELECT username, timestamp, returncode, max(TO_DATE (TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS'),'YYYY-MON-DD HH24:MI:SS')) over (partition by username) as "MAX_TS"
from dba_audit_trail
where action_name = 'LOGON'
and returncode > 0
) a
where timestamp = a."MAX_TS"
order by LAST_FAILED_LOGIN desc;


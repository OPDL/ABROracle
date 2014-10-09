set pagesize 9999
set linesize 9999
set feedback off
set verify off
set colsep '|'
DEFINE DAY_RANGE=7

-- never logged in
select username,'NEVER_LOGGED_IN' as "STATUS" from dba_users where account_status='OPEN' and username 
not in ( select username from dba_audit_trail where action_name 
in ('LOGOFF','LOGON') and username is not null );

-- last successful login
select aa.*,(case when  bb.username is null THEN '[DELETED]' ELSE '[ACTIVE]' END) as "STATUS" from (
select 
USERNAME
,TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS') as "LAST_SUCCESSFUL_LOGIN" 
--,trunc((sysdate - TIMESTAMP)*24) "HOURS AGO"
,trunc((sysdate - TIMESTAMP)) "DAYS_AGO"
from (
select username,returncode, TIMESTAMP, row_number() over (partition by username order by username, timestamp desc) as "RN" from
(
SELECT username, timestamp, returncode, max(TO_DATE (TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS'),'YYYY-MON-DD HH24:MI:SS')) over (partition by username) as max_ts
from dba_audit_trail
where action_name = 'LOGON'
and returncode = 0
) a
where timestamp = a.max_ts
) b
where b.rn = 1
) aa left outer join DBA_USERS bb
on aa.username = bb.username
order by aa."DAYS_AGO" asc, aa.username asc;

-- last failed login
select username,TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS') as "LAST_FAILED_LOGIN" , returncode from
(
SELECT username, timestamp, returncode, max(TO_DATE (TO_CHAR (TIMESTAMP, 'YYYY-MON-DD HH24:MI:SS'),'YYYY-MON-DD HH24:MI:SS')) over (partition by username) as "MAX_TS"
from dba_audit_trail
where action_name = 'LOGON'
and returncode > 0
) a
where timestamp = a."MAX_TS"
order by username asc;


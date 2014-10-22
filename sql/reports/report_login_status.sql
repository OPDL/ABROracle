set feedback off
set pagesize 9999
set linesize 9999
column USERNAME format A20
column ACCOUNT_STATUS format A20
column "DAY RANGE" format A20
column PROFILE format A20
DEFINE DAY_RANGE=7
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT ='MM/DD/YYYY HH24:MI:SS TZR TZD';
ALTER SESSION SET NLS_DATE_FORMAT ='MM-DD-YYYY HH24:MI:SS';

-- accounts expiring in N days from now or due to expire already
-- account that are past expiry_date but still open
-- There is no process that combs through accounts to reset 
-- their status vis a vis expiry date. The next time scott logs on his status will be updated accordingly,
-- and the grace period will begin

select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,'&DAY_RANGE' as "DAY RANGE"
,USERNAME, ACCOUNT_STATUS, LOCK_DATE, EXPIRY_DATE
from DBA_USERS
where 
EXPIRY_DATE < SYSDATE + &DAY_RANGE
AND
account_status IN ('OPEN', 'EXPIRED(GRACE)' )
AND
LOCK_DATE IS NULL
order by EXPIRY_DATE desc;

select 
SYSDATE as CURRENT_DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,USERNAME, ACCOUNT_STATUS, LOCK_DATE, EXPIRY_DATE, PROFILE 
from DBA_USERS
order by ACCOUNT_STATUS;


col username   format a15
col last_login format a25

alter session set NLS_TIMESTAMP_TZ_FORMAT='DD.MM.YYYY HH24:MI:SS';

Session altered.

select 
   username,
   last_login 
from
   dba_users 
order by 
   username';


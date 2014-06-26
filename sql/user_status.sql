set linesize 9999
set pagesize 9999
set colsep '|'
select username, account_status, lock_date, expiry_date, created, profile from dba_users;


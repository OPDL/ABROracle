select 'alter user ' || username || ' profile "APP_NO_EXPIRE_PW";' from dba_users where username like 'PROD_%';

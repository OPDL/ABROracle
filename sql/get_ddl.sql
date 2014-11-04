set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
column ddl format a3000
spool ddl.sql
SELECT DBMS_METADATA.GET_DDL('PROFILE','APP_NO_EXPIRE_PW') as ddl FROM DUAL;
SELECT DBMS_METADATA.GET_DDL('USER','UNVPRD') as ddl FROM DUAL;
spool off

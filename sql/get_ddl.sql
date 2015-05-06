set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
column ddl format a3000

SELECT DBMS_METADATA.GET_DDL('PROFILE','APP_NO_EXPIRE_PW') as ddl FROM DUAL;

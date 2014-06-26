exec dbms_stats.gather_table_stats('DSVRICHARDS','STAGE');
DECLARE
cs varchar2(100);
BEGIN
select SYS_CONTEXT('USERENV','CURRENT_SCHEMA') into cs from dual;
dbms_stats.gather_table_stats(cs,'STAGE');
END;
/


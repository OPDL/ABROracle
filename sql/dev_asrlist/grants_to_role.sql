-- set echo on
set serveroutput on
BEGIN
FOR tab IN (
SELECT table_name, owner
FROM dba_tables
WHERE upper(owner) in
(
'DEV_ASRLIST'
)
AND
upper(owner) not in
(
'SYS','SYSTEM','DBSNMP'
,'OUTLN','CTXSYS','EXFSYS'
,'XDB','ODMRSYS','WMSYS'
)
) 
LOOP
DBMS_OUTPUT.put_line(tab.owner||'.'||tab.table_name);
EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||tab.owner||'.'||tab.table_name||' TO ROLE_ASRLIST_RW';
END LOOP;
COMMIT;
END;
/



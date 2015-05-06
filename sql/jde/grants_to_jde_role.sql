-- set echo on
set serveroutput on
BEGIN
FOR tab IN (SELECT table_name, owner FROM dba_tables
WHERE upper(owner) in
('HPRDCTL','HPRDDTA','PRODCTL','PRODDTA','TPRDCTL','TPRDDTA'
,'HCRPCTL','HCRPDTA','CRPCTL','CRPDTA','TCRPCTL','TCRPDTA'
,'HTESTCTL','HTESTDTA','TESTCTL','TESTDTA','TTESTCTL','TTESTDTA')
AND
upper(owner) not in (
'SYS','SYSTEM','DBSNMP'
,'OUTLN','CTXSYS','EXFSYS'
,'XDB','ODMRSYS','WMSYS')) 
LOOP
DBMS_OUTPUT.put_line(tab.owner||'.'||tab.table_name);
EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||tab.owner||'.'||tab.table_name||' TO JDE_ROLE';
END LOOP;
COMMIT;
END;
/



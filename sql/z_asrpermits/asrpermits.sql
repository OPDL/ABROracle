set echo on
set serveroutput on
create role role_qa_appmetadata;
create role role_qa_asrpermits;
create role role_qa_asrlist;

BEGIN
FOR tab IN (SELECT table_name,owner
                  FROM   all_tables
                  WHERE  owner = 'QA_ASRPERMITS') 
LOOP
                DBMS_OUTPUT.put_line(tab.owner||'.'||tab.table_name);
                EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||tab.owner||'.'||tab.table_name||' TO role_qa_asrpermits';
END LOOP;
COMMIT;
END;
/
BEGIN
FOR tab IN (SELECT table_name,owner
                  FROM   all_tables
                  WHERE  owner = 'QA_APPMETADATA') 
LOOP
DBMS_OUTPUT.put_line(tab.table_name);
                DBMS_OUTPUT.put_line(tab.owner||'.'||tab.table_name);
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||tab.owner||'.'||tab.table_name||' TO role_qa_appmetadata';
END LOOP;
COMMIT;
END;
/
BEGIN
FOR tab IN (SELECT table_name,owner
                  FROM   all_tables
                  WHERE  owner = 'QA_ASRLIST') 
LOOP
DBMS_OUTPUT.put_line(tab.table_name);
                DBMS_OUTPUT.put_line(tab.owner||'.'||tab.table_name);
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||tab.owner||'.'||tab.table_name||' TO role_qa_asrlist';
END LOOP;
COMMIT;
END;
/



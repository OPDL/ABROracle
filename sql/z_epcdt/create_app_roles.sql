-- Adam Richards
-- drop and re create roles.
-- grant privs to roles
SET serveroutput ON
-- create temporary package to automate tasks
CREATE OR REPLACE PACKAGE abr
AS
  FUNCTION CREATE_ROLE(
      role_name VARCHAR2)
    RETURN INTEGER;
  FUNCTION GRANT_ROLE_ALL(
      s_name    VARCHAR2,
      role_name VARCHAR2)
    RETURN INTEGER;
END abr;
/
CREATE OR REPLACE PACKAGE BODY abr
IS
  -- Example:
  -- VAR OK number
  -- exec :OK := abr.create_role('ABRTEST');
  -- selct :OK from dual;
FUNCTION CREATE_ROLE(
    role_name VARCHAR2)
  RETURN INTEGER
IS
BEGIN
  BEGIN
    EXECUTE immediate 'drop role ' || role_name;
    DBMS_OUTPUT.put_line('Drop role '|| role_name);
  EXCEPTION
    -- ignore drop failure
  WHEN OTHERS THEN
    NULL;
  END;
  BEGIN
    DBMS_OUTPUT.put_line('create role '|| role_name);
    EXECUTE immediate 'create role ' || role_name;
    RETURN(0);
  EXCEPTION
  WHEN OTHERS THEN
    --"ORA-01921: role name 'x' conflicts with another user or role name"
    IF SQLCODE = -01921 THEN
      NULL;
    ELSE
      RETURN(1);
      --raise;
    END IF;
  END;
END CREATE_ROLE;
-- Example:
-- VAR OK number
-- exec :OK := abr.create_role('ABRTEST');
-- selct :OK from dual;
FUNCTION GRANT_ROLE_ALL(
    s_name    IN VARCHAR2,
    role_name IN VARCHAR2)
  RETURN INTEGER
IS
TYPE CurTyp
IS
  REF
  CURSOR;
    v_cursor CurTyp;
    v_record all_tables%ROWTYPE;
    v_stmt_str VARCHAR2(500);
  BEGIN
    -- Dynamic SQL statement with placeholder:
    v_stmt_str := 'SELECT * FROM   all_tables WHERE  upper(owner) = upper(''' || s_name || ''')';
    DBMS_OUTPUT.put_line('BEGIN GRANT_ROLE_ALL ' || s_name || ' ' || role_name);
    OPEN v_cursor FOR v_stmt_str;
    LOOP
      FETCH v_cursor INTO v_record;
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.put_line(v_record.OWNER||'.'||v_record.TABLE_NAME || ' ' || role_name);
      EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||v_record.owner||'.'||v_record.table_name||' TO ' || role_name;
    END LOOP;
  -- Close cursor:
  CLOSE v_cursor;
  RETURN(0);
EXCEPTION
WHEN OTHERS THEN
  -- return(1);
  raise;
END GRANT_ROLE_ALL;
END abr;
/
-- DO THE WORK
var ok NUMBER;
EXEC :ok := abr.create_role('role_rw_dev_appmetadata');
EXEC :ok := abr.create_role('role_rw_dev_asrpermits');
EXEC :ok := abr.create_role('role_rw_dev_asrlist');
EXEC :ok := abr.create_role('role_rw_qa_appmetadata');
EXEC :ok := abr.create_role('role_rw_qa_asrpermits');
EXEC :ok := abr.create_role('role_rw_qa_asrlist');
EXEC :ok := abr.grant_role_all('dev_appmetadata', 'role_rw_dev_appmetadata');
EXEC :ok := abr.grant_role_all('dev_asrpermits', 'role_rw_dev_asrpermits');
EXEC :ok := abr.grant_role_all('dev_asrlist', 'role_rw_dev_asrlist');
EXEC :ok := abr.grant_role_all('qa_appmetadata', 'role_rw_qa_appmetadata');
EXEC :ok := abr.grant_role_all('qa_asrpermits', 'role_rw_qa_asrpermits');
EXEC :ok := abr.grant_role_all('qa_asrlist', 'role_rw_qa_asrlist');
-- CLEAN UP
DROP PACKAGE abr;

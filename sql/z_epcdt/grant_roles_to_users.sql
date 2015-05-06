-- Adam Richards
-- drop and re create roles.
-- grant privs to roles
SET serveroutput ON
-- create temporary package to automate tasks
CREATE OR REPLACE PACKAGE abr
AS
  FUNCTION GRANT_ROLE_TO_USERS(
      u_key     VARCHAR2,
      role_name VARCHAR2)
    RETURN INTEGER;
END abr;
/
CREATE OR REPLACE PACKAGE BODY abr
IS
  -- Example:
  -- VAR OK number
  -- exec :OK := abr.create_role('ABRTEST');
  -- select :OK from dual;
FUNCTION GRANT_ROLE_TO_USERS(
    u_key     IN VARCHAR2,
    role_name IN VARCHAR2)
  RETURN INTEGER
IS
TYPE CurTyp
IS
  REF
  CURSOR;
    v_cursor CurTyp;
    v_record all_users%ROWTYPE;
    v_stmt_str VARCHAR2(1000);
  BEGIN
    v_stmt_str := 'SELECT * FROM all_users WHERE upper(username) like ''' || u_key || ''' AND upper(username) not in ' || '(''SYS'',''SYSTEM'',''DBSNMP'',''OUTLN'',''CTXSYS'',''EXFSYS'',''XDB'',''ODMRSYS'',''WMSYS'')';
    
    DBMS_OUTPUT.put_line('BEGIN GRANT_ROLE_TO_USERS ' || u_key || ' ' || role_name);
    OPEN v_cursor FOR v_stmt_str;
    LOOP FETCH v_cursor INTO v_record;
    
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.put_line('GRANT ROLE: ' || role_name || ' TO USER: ' || v_record.username);
   --  EXECUTE IMMEDIATE 'GRANT ' || role_name || ' TO ' || v_record.username ;
  END LOOP;
  -- Close cursor:
  CLOSE v_cursor;
  RETURN(0);
EXCEPTION
WHEN OTHERS THEN
  -- return(1);
  raise;
END GRANT_ROLE_TO_USERS;
END abr;
/
-- DO THE WORK
var ok NUMBER;
EXEC :ok := abr.grant_role_to_users('DSV%', 'role_rw_dev_appmetadata');
EXEC :ok := abr.grant_role_to_users('DSV%', 'role_rw_dev_asrlist');
EXEC :ok := abr.grant_role_to_users('DSV%', 'role_rw_dev_asrpermits');

-- CLEAN UP
DROP PACKAGE abr;

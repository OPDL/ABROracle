-- Adam Richards
-- drop and re create roles.
-- grant privs to roles
set serveroutput on

-- create temporary package to automate tasks
CREATE OR REPLACE PACKAGE abr as
      FUNCTION CREATE_ROLE(role_name varchar2) RETURN integer;
      FUNCTION GRANT_ROLE_ALL(s_name varchar2, role_name varchar2) RETURN integer;
END abr;
/
CREATE OR REPLACE PACKAGE BODY abr is
	-- Example:
	-- VAR OK number
	-- exec :OK := abr.create_role('ABRTEST');
	-- selct :OK from dual;
	FUNCTION CREATE_ROLE(role_name varchar2) RETURN integer is
	begin
	
	begin
		execute immediate 'drop role ' || role_name;
		DBMS_OUTPUT.put_line('Drop role '|| role_name);
		exception
		-- ignore drop failure
		when others then
			null;
	end;

	begin
	DBMS_OUTPUT.put_line('create role '|| role_name);
	execute immediate 'create role ' || role_name;
	return(0);
	exception
	when others then
	--"ORA-01921: role name 'x' conflicts with another user or role name"
	if sqlcode = -01921 then
		null;
	else
		return(1);
		--raise;
	end if;
	end;
	end CREATE_ROLE;

	-- Example:
	-- VAR OK number
	-- exec :OK := abr.create_role('ABRTEST');
	-- selct :OK from dual;
	FUNCTION GRANT_ROLE_ALL(s_name in varchar2, role_name in varchar2) RETURN integer is
TYPE CurTyp  IS REF CURSOR;
  v_cursor        CurTyp;
  v_record        all_tables%ROWTYPE;
  v_stmt_str      VARCHAR2(500);
BEGIN
  -- Dynamic SQL statement with placeholder:
  v_stmt_str := 'SELECT * FROM   all_tables WHERE  upper(owner) = upper(''' || s_name || ''')';

    DBMS_OUTPUT.put_line('BEGIN GRANT_ROLE_ALL ' ||  s_name || ' ' || role_name);
  OPEN v_cursor FOR v_stmt_str;
  LOOP FETCH v_cursor INTO v_record;
    EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.put_line(v_record.OWNER||'.'||v_record.TABLE_NAME ||  ' '  || role_name);
 EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||v_record.owner||'.'||v_record.table_name||' TO ' || role_name;
  END LOOP;

  -- Close cursor:
  CLOSE v_cursor;

		return(0);
	exception
	when others then
		-- return(1);
		raise;
	END GRANT_ROLE_ALL;
  END abr;
/
-- DO THE WORK
var ok number;
exec :ok := abr.create_role('role_rw_dev_appmetadata');
exec :ok := abr.create_role('role_rw_dev_asrpermits');
exec :ok := abr.create_role('role_rw_dev_asrlist');
exec :ok := abr.create_role('role_rw_qa_appmetadata');
exec :ok := abr.create_role('role_rw_qa_asrpermits');
exec :ok := abr.create_role('role_rw_qa_asrlist');
exec :ok := abr.grant_role_all('dev_appmetadata', 'role_rw_dev_appmetadata');
exec :ok := abr.grant_role_all('dev_asrpermits', 'role_rw_dev_asrpermits');
exec :ok := abr.grant_role_all('dev_asrlist', 'role_rw_dev_asrlist');
exec :ok := abr.grant_role_all('qa_appmetadata', 'role_rw_qa_appmetadata');
exec :ok := abr.grant_role_all('qa_asrpermits', 'role_rw_qa_asrpermits');
exec :ok := abr.grant_role_all('qa_asrlist', 'role_rw_qa_asrlist');

-- CLEAN UP
drop package abr;


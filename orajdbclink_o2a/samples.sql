-- configure MYSQLSRV datasource with jtds jdbc driver (http://jtds.sourceforge.net/)

Insert into JDBC_DBLINK (DATA_SOURCE_NAME,URL,DBUSER,DBPASSWORD,DRIVER) values ('MYSQLSRV','jdbc:jtds:sqlserver://mysqlsrv.mydomain:1433/mydatabase','myuser','mypwd','net.sourceforge.jtds.jdbc.Driver');

commit;

-- test jcursor
declare
  v_cursor   orajdbclink_o2a.jcursor:= orajdbclink_o2a.jcursor('select col1, col2, col5 from sqlservertable','MYSQLSRV',3);
begin

  dbms_java.set_output(10000);

  v_cursor.init;
  v_cursor.open;


  while v_cursor.dofetch = 1 loop
    dbms_output.put_line(v_cursor.get_string(1));
    dbms_output.put_line(v_cursor.get_string(2));
    dbms_output.put_line(v_cursor.get_string(3));
  end loop;

  
  v_cursor.close;  

exception
  when others then
    dbms_output.put_line('err: '||sqlerrm(sqlcode));
    v_cursor.close;  
end;

-- test jcall
declare
  v_call   orajdbclink_o2a.jcall:= orajdbclink_o2a.jcall('insert into sqlservertable (col) values (?)','MYSQLSRV');
begin

  dbms_java.set_output(10000);

  v_call.init;
  v_call.bind(1,'hello');
  v_call.executecall;
  v_call.close;
  
exception
  when others then
    dbms_output.put_line('err: '||sqlerrm(sqlcode));
    v_call.rollback;  -- if something bad happens we rollback the jcall connection
    v_call.close;  
end;


-- test transaction isolation
declare
  v_call     orajdbclink_o2a.jcall;
  v_cursor   orajdbclink_o2a.jcursor;
begin

  dbms_java.set_output(10000);

  -- suppose "sqlservertable" to be empty
  v_call:= orajdbclink_o2a.jcall('insert into sqlservertable (col) values (?)','MYSQLSRV');
  v_call.init;
  v_call.bind(1,'hello');
  v_call.executecall;
  v_call.close;
  
  -- actually v_call is not committed
  
  v_cursor:= orajdbclink_o2a.jcursor('select col from sqlservertable','MYSQLSRV',1);
  v_cursor.init;
  v_cursor.open;


  while v_cursor.dofetch = 1 loop
    dbms_output.put_line(v_cursor.get_string(1)); --this will print out a 'hello' because v_cursor uses the same jdbc connection
  end loop;
  
  v_cursor.close;

  raise_application_error(-20002,'Something bad happens');  -- something bad happens, so v_call will be rolled back
                                                            -- if we remove this line the connectionmanager will commit the 
                                                            -- transaction at the end of the pl/sql call (oracle.aurora.memoryManager.EndOfCallRegistry).
  
exception
  when others then
    dbms_output.put_line('err: '||sqlerrm(sqlcode));
    v_call.rollback;  -- if something bad happens we rollback the jcall connection
    v_call.close;  
end;

-- test "distributed" transactions
declare
  v_call     orajdbclink_o2a.jcall;
begin

  dbms_java.set_output(10000);

  -- suppose "sqlservertable" to be empty
  v_call:= orajdbclink_o2a.jcall('insert into sqlservertable (col) values (?)','MYSQLSRV');
  v_call.init;
  v_call.bind(1,'hello'); -- USE BIND VARIABLES !!!!
  v_call.executecall;
  v_call.close;
  
  -- actually v_call is not committed
  

  insert into mytable values(1,2,3);

  -- NOTE: If somthing goes wrong before that commit all will goes fine: the local and the remote transaction
  --       will be rolled back
  
  commit;

  -- WARNING: if we loose the connection with the remote host here (between "commit" and "end") we will lost the jcall transaction !!
  --          SO USE IT AT YOUR OWN RISK
  
exception
  when others then
    rollback;
    v_call.rollback;  -- if something bad happens we rollback the jcall connection
    v_call.close;  
    dbms_output.put_line('err: '||sqlerrm(sqlcode));
end;

-- create a package for pipelined views in your application schema
-- NOTE: first grant all on orajdbclink_o2a.jcursor to <your application schema>

create or replace
package MYSQLSRV as

  type view_item_record is record
  (
       code                varchar2(255),
       description         varchar2(2000)
  );
  
  type view_item_table is table of view_item_record;
  
  function view_item
  return view_item_table
  pipelined;

end MYSQLSRV;
/

create or replace
package body MYSQLSRV as

  function view_item
  return view_item_table
  pipelined
  as
    v_cursor              orajdbclink_o2a.jcursor:= orajdbclink_o2a.jcursor('select code, description from item_table','MYSQLSRV',2); --define the cursor query
    v_record              view_item_record;
  begin

  v_cursor.init; -- open connection, and prepare query
  v_cursor.open; -- execute query


  while v_cursor.dofetch = 1 loop -- fetch query results into your view record
    v_record.code:= v_cursor.get_string(1); -- code
    v_record.description:= v_cursor.get_string(2); -- description
    pipe row (v_record); -- pipe row to the query
  end loop;

  
  v_cursor.close;  -- close resources

  exception
    when others then -- if something happens
      v_cursor.close;  -- close resources
      raise; -- raise the exception
  end;

end mysqlsrv;
/


-- test your new view 

set serveroutput on;

begin
 dbms_java.set_output(10000);
end;
/

-- o yeah... look at this...
select * from table(mysqlsrv.view_item)

-- now probably you can
--  1) use it like a normal view but it will be slooow to process where clauses
--  2) add a parameter where clause to the function to have the remote database ose indexes
--  3) create a materialized view on top of it index it and use it as you like



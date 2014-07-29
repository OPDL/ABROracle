set sqlprefix off;

create user orajdbclink_o2a identified by orajdbclink_o2a;
grant connect,resource, javauserpriv, javasyspriv to orajdbclink_o2a;

connect orajdbclink_o2a/orajdbclink_o2a&connstr;

@net.sf.orajdbclink.oracletoany.ConnectionConfig.sql
@net.sf.orajdbclink.oracletoany.ConnectionManager.sql
@net.sf.orajdbclink.oracletoany.Cursor.sql
@net.sf.orajdbclink.oracletoany.Call.sql

CREATE OR REPLACE TYPE jcursor AS OBJECT 
EXTERNAL NAME 'net.sf.orajdbclink.oracletoany.Cursor'
LANGUAGE JAVA
USING SQLData
 (stmt        varchar2(32767) external name 'sql',
  data_source varchar2(20)    external name 'dataSource',
  colsno      number          external name 'colsno',
  member procedure init 
  as language java
  name 'init()',
  
  member procedure bind(pos number, v_val varchar2)
  as language java
  name 'bind(int, java.lang.String)',


  member procedure bind(pos number, v_val number)
  as language java
  name 'bind(int, java.lang.Double)',


  member procedure bind(pos number, v_val date)
  as language java
  name 'bind(int, java.sql.Date)',
  
  
  member function get_cursor
  return SYS_REFCURSOR
  external name 'getCursor() return java.sql.ResultSet',
 
  member procedure open 
  as language java
  name 'open()',

  member function dofetch
  return number
  external name 'fetch() return int',

  member function get_string(column_name varchar2)
  return varchar2
  external name 'getString(java.lang.String) return java.lang.String',

  member function get_number(column_name varchar2)
  return number
  external name 'getNumber(java.lang.String) return java.lang.Double',

  member function get_date(column_name varchar2)
  return date
  external name 'getDate(java.lang.String) return java.sql.Date',

  member function get_string(column_index number)
  return varchar2
  external name 'getString(int) return java.lang.String',

  member function get_number(column_index number)
  return number
  external name 'getNumber(int) return java.lang.Double',

  member function get_date(column_index number)
  return date
  external name 'getDate(int) return java.sql.Date',

  member procedure close 
  as language java
  name 'close()'
 );
/

CREATE OR REPLACE TYPE jcall AS OBJECT 
EXTERNAL NAME 'net.sf.orajdbclink.oracletoany.Call'
LANGUAGE JAVA
USING SQLData
 (stmt        varchar2(32767) external name 'sql',
  data_source varchar2(20)    external name 'dataSource',

  member procedure init 
  as language java
  name 'init()',
  
  member procedure bind(pos number, v_val varchar2)
  as language java
  name 'bind(int, java.lang.String)',


  member procedure bind(pos number, v_val number)
  as language java
  name 'bind(int, java.lang.Double)',


  member procedure bind(pos number, v_val date)
  as language java
  name 'bind(int, java.sql.Date)',
  
  
  member procedure registeroutstring(pos number)
  as language java
  name 'registerOutString(int)',


  member procedure registeroutdouble(pos number)
  as language java
  name 'registerOutDouble(int)',


  member procedure registeroutdate(pos number)
  as language java
  name 'registerOutDate(int)',

  member function get_string(column_index number)
  return varchar2
  external name 'getOutString(int) return java.lang.String',

  member function get_number(column_index number)
  return number
  external name 'getOutDouble(int) return java.lang.Double',

  member function get_date(column_index number)
  return date
  external name 'getOutDate(int) return java.sql.Date',

  member procedure executecall
  as language java
  name 'execute()',


  member procedure close
  as language java
  name 'close()',
  
  member procedure rollback
  as language java
  name 'rollback()'
  
);
/

create table JDBC_DBLINK
(
    data_source_name     varchar2(20) primary key,
    url                  varchar2(4000),
    dbuser               varchar2(255),
    dbpassword           varchar2(255),
    driver               varchar2(4000)
);


CREATE OR REPLACE TRIGGER UPPER_JDBC_DBLINK_NAME
BEFORE INSERT OR UPDATE
ON JDBC_DBLINK
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN

   :new.data_source_name:= upper(:new.data_source_name);
      
END;
/

grant all on orajdbclink_o2a.jcursor to public;
grant all on orajdbclink_o2a.jcall to public;
grant all on orajdbclink_o2a.jdbc_dblink to public;


exit;


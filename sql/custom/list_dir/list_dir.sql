That grant must be given to the owner of the procedure..  Allows them to read 
directories.

ops$tkyte@8i> create global temporary table DIR_LIST
  2  ( filename varchar2(255) )
  3  on commit delete rows
  4  /

Table created.

ops$tkyte@8i> create or replace
  2     and compile java source named "DirList"
  3  as
  4  import java.io.*;
  5  import java.sql.*;
  6  
  7  public class DirList
  8  {
  9  public static void getList(String directory)
 10                     throws SQLException
 11  {
 12      File path = new File( directory );
 13      String[] list = path.list();
 14      String element;
 15  
 16      for(int i = 0; i < list.length; i++)
 17      {
 18          element = list[i];
 19          #sql { INSERT INTO DIR_LIST (FILENAME)
 20                 VALUES (:element) };
 21      }
 22  }
 23  
 24  }
 25  /

Java created.

ops$tkyte@8i> 
ops$tkyte@8i> create or replace
  2  procedure get_dir_list( p_directory in varchar2 )
  3  as language java
  4  name 'DirList.getList( java.lang.String )';
  5  /

Procedure created.

ops$tkyte@8i> 
ops$tkyte@8i> exec get_dir_list( '/tmp' );

PL/SQL procedure successfully completed.

ops$tkyte@8i> select * from dir_list where rownum < 5;

FILENAME
------------------------------------------------------
data.dat
.rpc_door
.pcmcia
ps_data


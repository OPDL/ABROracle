CREATE OR REPLACE AND RESOLVE JAVA SOURCE NAMED "net.sf.orajdbclink.oracletoany.Cursor"
AS
package net.sf.orajdbclink.oracletoany;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLData;
import java.sql.SQLException;
import java.sql.SQLInput;
import java.sql.SQLOutput;
import oracle.aurora.memoryManager.Callback;
import oracle.aurora.memoryManager.EndOfCallRegistry;


public class Cursor implements SQLData, Callback {
  /* All static because subsequent calls are done with different
   * instances and we need to keep the state,
   * but different connections use different jvms so
   * this will not cause problems
   */
  private static ResultSet rs;
  private static PreparedStatement stmt;
  private static Connection conn;
  private static String sql;
  private static String dataSource;
  private static int colsno;

  private static String sql_type= "ORAJDBCLINK_O2A.JCURSOR";
  
  public Cursor() 
  {
  }

  /* EndOfCallRegistry: cleanup static fields, close resources */
  public void act(Object obj)
  {
      sql= null;
      dataSource= null;
      colsno= 0;
      try { rs.close(); } catch (Exception e) { /* ignore */ }
      rs=null;
      try { stmt.close(); } catch (Exception e) { /* ignore */ }
      stmt=null;
  }

  public void setSql(String sql)
  {
	  Cursor.sql = sql;
  }


  public String getSql()
  {
    return sql;
  }


  public void setDataSource(String dataSource)
  {
    Cursor.dataSource = dataSource;
  }


  public String getDataSource()
  {
    return dataSource;
  }
  
  
  public String getSQLTypeName() throws SQLException {
    return sql_type;
  }
 
  public void readSQL(SQLInput stream, String typeName)
    throws SQLException {
    sql_type = typeName;
    
      sql = stream.readString();
      dataSource = stream.readString();
    //System.out.println("r sql: "+sql);
    //System.out.println("r dataSource: "+dataSource);
  }
 
  public void writeSQL(SQLOutput stream) throws SQLException {

    stream.writeString(""); //faster we dont need it
    stream.writeString(""); //faster we dont need it
    stream.writeInt(colsno);
    //System.out.println("w sql: "+sql);
    //System.out.println("w dataSource: "+dataSource);
  }
  
  public void init()
  throws SQLException
  {
    //System.out.println("i sql: "+sql);
    //System.out.println("i dataSource: "+dataSource);
  
    conn= ConnectionManager.getInstance().getConnection(dataSource);    
    
    EndOfCallRegistry.registerCallback(this);
    
    stmt= conn.prepareStatement(sql);
    
    //System.out.println("stmt: "+stmt);
  }
  
  public void bind(int i, String val)
  throws SQLException
  {
    stmt.setString(i, val);
  }

  public void bind(int i, Double val)
  throws SQLException
  {
    stmt.setDouble(i, val.doubleValue());
  }

  public void bind(int i, Date val)
  throws SQLException
  {
    stmt.setDate(i, val);
  }


  public ResultSet getCursor()
  throws SQLException
  {
    return stmt.executeQuery();
  }


  public void open()
  throws SQLException
  {
    //System.out.println("stmt: "+stmt);
    rs= stmt.executeQuery();
    colsno= rs.getMetaData().getColumnCount();
  }

  public int fetch()
  throws SQLException
  {
     return (rs.next())?1:0;
  }

  public String getString(String str)
  throws SQLException
  {
    return rs.getString(str);
  }

  public Double getNumber(String str)
  throws SQLException
  {
    return new Double(rs.getDouble(str));
  }

  public Date getDate(String str)
  throws SQLException
  {
    return rs.getDate(str);
  }

  public String getString(int idx)
  throws SQLException
  {
    return rs.getString(idx);
  }

  public Double getNumber(int idx)
  throws SQLException
  {
    return new Double(rs.getDouble(idx));
  }

  public Date getDate(int idx)
  throws SQLException
  {
    return rs.getDate(idx);
  }
  
  public void close()
  throws SQLException
  {
      try { rs.close(); } catch (Exception e) { /* ignore */ }
      rs=null;
      try { stmt.close(); } catch (Exception e) { /* ignore */ }
      stmt=null;
  }

}
/


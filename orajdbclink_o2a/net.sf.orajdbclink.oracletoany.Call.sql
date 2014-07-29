CREATE OR REPLACE AND RESOLVE JAVA SOURCE NAMED "net.sf.orajdbclink.oracletoany.Call"
AS
package net.sf.orajdbclink.oracletoany;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.SQLData;
import java.sql.SQLException;
import java.sql.SQLInput;
import java.sql.SQLOutput;
import java.sql.Types;

import oracle.aurora.memoryManager.Callback;
import oracle.aurora.memoryManager.EndOfCallRegistry;


public class Call implements SQLData, Callback {
  /* All static because subsequent calls are done with different
   * instances and we need to keep the state,
   * but different connections use different jvms so
   * this will not cause problems
   */

  private static CallableStatement stmt;
  private static Connection conn;
  private static String sql;
  private static String dataSource;

  private static String sql_type= "ORAJDBCLINK_O2A.JCALL";
  
  public Call() 
  {
  }

  /* EndOfCallRegistry: cleanup static fields, close resources */
  public void act(Object obj)
  {
      sql= null;
      dataSource= null;
      try { stmt.close(); } catch (Exception e) { /* ignore */ }
      stmt=null;
  }

  public void setSql(String sql)
  {
    Call.sql = sql;
  }


  public String getSql()
  {
     return sql;
  }


  public void setDataSource(String dataSource)
  {
	  Call.dataSource = dataSource;
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
    //System.out.println("w sql: "+sql);
    //System.out.println("w dataSource: "+dataSource);
  }
  
  public void init()
  throws SQLException
  {
    //System.out.println("i sql: "+sql);
    //System.out.println("i dataSource: "+dataSource);
  
    conn= ConnectionManager.getInstance().getConnection(dataSource);    
    
    stmt= conn.prepareCall(sql);

    EndOfCallRegistry.registerCallback(this);
    
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

  public void registerOutString(int i)
  throws SQLException
  {
    stmt.registerOutParameter(i,Types.VARCHAR);
  }

  public void registerOutDouble(int i)
  throws SQLException
  {
    stmt.registerOutParameter(i,Types.DOUBLE);
  }

  public void registerOutDate(int i)
  throws SQLException
  {
    stmt.registerOutParameter(i,Types.DATE);
  }

  public String getOutString(int i)
  throws SQLException
  {
    return stmt.getString(i);
  }

  public Double getOutDouble(int i)
  throws SQLException
  {
    return new Double(stmt.getDouble(i));
  }

  public Date getOutDate(int i)
  throws SQLException
  {
    return stmt.getDate(i);
  }

  public void execute()
  throws SQLException
  {
    //System.out.println("stmt: "+stmt);
    stmt.execute();
  }
  
  public void close()
  throws SQLException
  {
    //System.out.println("close called");
    stmt.close();
  }

  public void rollback()
  throws SQLException
  {
    //System.out.println("close called");
    try { conn.rollback(); } catch (Exception ex) {}
  }
}
/


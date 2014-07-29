CREATE OR REPLACE AND RESOLVE JAVA SOURCE NAMED "net.sf.orajdbclink.oracletoany.ConnectionConfig"
AS
package net.sf.orajdbclink.oracletoany;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class ConnectionConfig 
{
  private String dsName;
  private String url;
  private String user;
  private String password;
  private String driver;

  public ConnectionConfig(Connection conn, String dsName, String confTable)
  throws SQLException
  {
     this.dsName= dsName;
     PreparedStatement stmt= conn.prepareStatement("select * from ORAJDBCLINK_O2A.JDBC_DBLINK where data_source_name= ?");
     stmt.setString(1,dsName);
     ResultSet rs= stmt.executeQuery();
     while (rs.next())
     {
         url= rs.getString("url");
         user= rs.getString("dbuser");
         password= rs.getString("dbpassword");
         driver= rs.getString("driver");
     }
     
     rs.close();
     stmt.close();
    
     if (url==null)
    	 throw new RuntimeException("Datasource '"+dsName+"' not found check ORAJDBCLINK_O2A.JDBC_DBLINK table");
  }


  public void setDsName(String dsName)
  {
    this.dsName = dsName;
  }


  public String getDsName()
  {
    return dsName;
  }


  public void setUrl(String url)
  {
    this.url = url;
  }


  public String getUrl()
  {
    return url;
  }


  public void setUser(String user)
  {
    this.user = user;
  }


  public String getUser()
  {
    return user;
  }


  public void setPassword(String password)
  {
    this.password = password;
  }


  public String getPassword()
  {
    return password;
  }

  public String getDriver()
  {
    return driver;
  }
}
/


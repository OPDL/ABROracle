CREATE OR REPLACE AND RESOLVE JAVA SOURCE NAMED "net.sf.orajdbclink.oracletoany.ConnectionManager"
AS
package net.sf.orajdbclink.oracletoany;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import oracle.aurora.memoryManager.Callback;
import oracle.aurora.memoryManager.EndOfCallRegistry;

public class ConnectionManager implements Callback
{
  private static ConnectionManager cm;
  private HashMap conns;
  private Connection iconn;
  private String confTable;
  
  private ConnectionManager()
  throws SQLException
  {

     Properties props= new Properties();
     conns= new HashMap();

     try
     {
        props.load(ConnectionManager.class.getResourceAsStream("cm.properties"));
     }
     catch (Exception e)
     {}
     
     
     iconn= DriverManager.getConnection("jdbc:default:connection:");
     confTable= props.getProperty("configuration-table");

  }

  
  public void act(Object obj)
  {
      Iterator i= conns.entrySet().iterator();
      
      while (i.hasNext())
      {
          Map.Entry en= (Map.Entry)i.next();

            try
            {
            	
                Connection conn= ((Connection)en.getValue());
                if (!conn.isReadOnly()) conn.commit();
                conn.close();
                System.out.println("Closed connection for: "+en.getKey());
            }
            catch (Exception e)
            { /* ignore */ }
      }
      
      try
      {
        iconn.close();
      }
      catch (Exception e)
      { /* ignore */ }

      iconn= null;      
      conns= null;
      confTable= null;
      cm= null;
  }

  
  public static ConnectionManager getInstance()
  throws SQLException
  {
  
     if (cm==null)
     {
       System.out.println("new ConnectionManager instance");
       synchronized (ConnectionManager.class)
       {
          cm= new ConnectionManager();
       }
       EndOfCallRegistry.registerCallback(cm);
     }

     return cm;
  }
  
  public Connection getConnection(String dsName)
  throws SQLException
  {
	  Connection conn;
    
    if ((conn=(Connection)conns.get(dsName))==null)
    {
      System.out.println("New connection for: "+dsName);
      ConnectionConfig cc= new ConnectionConfig(iconn, dsName, confTable);
      System.out.println("driver: "+cc.getDriver());
      
      try {
		Class.forName(cc.getDriver());
	  } catch (ClassNotFoundException e) {
		  throw new RuntimeException(e);
	  }
	  
      conn= (Connection)DriverManager.getConnection(cc.getUrl(), cc.getUser(), cc.getPassword());
      conn.setAutoCommit(false);
      conns.put(dsName,conn);
    }
    
    return conn;
  }
}
/


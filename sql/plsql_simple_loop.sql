SET serveroutput ON
BEGIN
  FOR u IN
  (SELECT username
  FROM dba_users
  WHERE upper(username) LIKE '%'
  AND upper(username) NOT IN ( 'SYS','SYSTEM','DBSNMP' ,'OUTLN','CTXSYS','EXFSYS' ,'XDB','ODMRSYS','WMSYS' )
  )
  LOOP
    DBMS_OUTPUT.put_line(u.username);
    -- EXECUTE IMMEDIATE 'GRANT ROLE_ASRLIST_RW TO ' || u.username;
  END LOOP;
  COMMIT;
END;
/
SET serveroutput ON
DECLARE
  l_retval pls_integer;
  l_retval2 pls_integer;
  l_session dbms_ldap.session;
  l_ldap_host   VARCHAR2(256);
  l_ldap_port   VARCHAR2(256);
  l_ldap_user   VARCHAR2(256);
  l_ldap_passwd VARCHAR2(256);
  l_ldap_base   VARCHAR2(256);
BEGIN
  l_retval                := -1;
  dbms_ldap.use_exception := TRUE;
  l_ldap_host             := 'mcp.epc.com';
  l_ldap_port             := '389';
  -- l_ldap_user               := 'cn=firstname_lastname,l=amer,dc=oracle,dc=com';
  -- l_ldap_user   := 'epc\dsvrichards';
  l_ldap_user   := 'dsvrichards@epc.com';
  l_ldap_passwd := '&password';
  l_session     := dbms_ldap.init( l_ldap_host, l_ldap_port );
  l_retval      := dbms_ldap.simple_bind_s( l_session, l_ldap_user, l_ldap_passwd );
  dbms_output.put_line( 'Return value: ' || l_retval );
  l_retval2 := dbms_ldap.unbind_s( l_session );
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line (rpad('ldap session ',25,' ') || ': ' || rawtohex(SUBSTR(l_session,1,8)) || '(returned from init)');
  dbms_output.put_line( 'error: ' || sqlerrm||' '||SQLCODE );
  dbms_output.put_line( 'user: ' || l_ldap_user );
  dbms_output.put_line( 'host: ' || l_ldap_host );
  dbms_output.put_line( 'port: ' || l_ldap_port );
  l_retval := dbms_ldap.unbind_s( l_session );
END;
/

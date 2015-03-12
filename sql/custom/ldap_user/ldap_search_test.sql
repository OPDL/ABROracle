set serveroutput on size 30000
DECLARE
  retval PLS_INTEGER;
  my_session DBMS_LDAP.session;
  my_attrs DBMS_LDAP.string_collection;
  my_message DBMS_LDAP.message;
  my_entry DBMS_LDAP.message;
  entry_index PLS_INTEGER;
  my_dn        VARCHAR2(256);
  my_attr_name VARCHAR2(256);
  my_ber_elmt DBMS_LDAP.ber_element;
  attr_index PLS_INTEGER;
  i PLS_INTEGER;
  my_vals DBMS_LDAP.STRING_COLLECTION ;
  ldap_host   VARCHAR2(256);
  ldap_port   VARCHAR2(256);
  ldap_user   VARCHAR2(256);
  ldap_passwd VARCHAR2(256);
  ldap_base   VARCHAR2(256);
  objectClass   VARCHAR2(256);
BEGIN
  retval := -1;
  -- Please customize the following variables as needed
  -- objectClass := 'organizationalUnit';
  objectClass := 'group';
  ldap_host  := 'mcp.epc.com' ;
  ldap_port  := '389';
  ldap_user  := 'AppAsrRBD@epc.com';
  ldap_passwd:= 'Nxr7WRB3';
  ldap_base  := 'dc=epc,dc=com';
  -- end of customizable settings
  DBMS_OUTPUT.PUT('DBMS_LDAP Search Example ');
  DBMS_OUTPUT.PUT_LINE('to directory .. ');
  DBMS_OUTPUT.PUT_LINE(RPAD('LDAP Host ',25,' ') || ': ' || ldap_host);
  DBMS_OUTPUT.PUT_LINE(RPAD('LDAP Port ',25,' ') || ': ' || ldap_port);
  -- Choosing exceptions to be raised by DBMS_LDAP library.
  DBMS_LDAP.USE_EXCEPTION := TRUE;
  my_session              := DBMS_LDAP.init(ldap_host,ldap_port);
  DBMS_OUTPUT.PUT_LINE (RPAD('Ldap session ',25,' ') || ': ' || RAWTOHEX(SUBSTR(my_session,1,8)) || '(returned from init)');
  -- bind to the directory
  retval := DBMS_LDAP.simple_bind_s(my_session, ldap_user, ldap_passwd);
  DBMS_OUTPUT.PUT_LINE(RPAD('simple_bind_s Returns ',25,' ') || ': ' || TO_CHAR(retval));
  -- issue the search
  my_attrs(1) := '*'; -- retrieve all attributes
  my_attrs(1) := 'DN'; -- just get DN
  -- DBMS_LDAP.SCOPE_ONELEVEL
  -- retval      := DBMS_LDAP.search_s(my_session, ldap_base, DBMS_LDAP.SCOPE_SUBTREE, '(&(samaccountname=*)(objectclass=user))', my_attrs, 0, my_message);
  retval      := DBMS_LDAP.search_s(my_session, ldap_base, DBMS_LDAP.SCOPE_SUBTREE, '(objectclass=' || objectClass || ')', my_attrs, 0, my_message);
  DBMS_OUTPUT.PUT_LINE(RPAD('search_s Returns ',25,' ') || ': ' || TO_CHAR(retval));
  DBMS_OUTPUT.PUT_LINE (RPAD('LDAP message  ',25,' ') || ': ' || RAWTOHEX(SUBSTR(my_message,1,8)) || '(returned from search_s)');
  -- count the number of entries returned
  retval := DBMS_LDAP.count_entries(my_session, my_message);
  DBMS_OUTPUT.PUT_LINE(RPAD('Number of Entries ',25,' ') || ': ' || TO_CHAR(retval));
  DBMS_OUTPUT.PUT_LINE('---------------------------------------------------');
  -- get the first entry
  my_entry    := DBMS_LDAP.first_entry(my_session, my_message);
  entry_index := 1;
  -- Loop through each of the entries one by one
  WHILE my_entry IS NOT NULL
  LOOP
    -- print the current entry
    my_dn := DBMS_LDAP.get_dn(my_session, my_entry);
    -- DBMS_OUTPUT.PUT_LINE ('        entry #' || TO_CHAR(entry_index) ||
    -- ' entry ptr: ' || RAWTOHEX(SUBSTR(my_entry,1,8)));
    DBMS_OUTPUT.PUT_LINE ('        dn: ' || my_dn);
    my_attr_name       := DBMS_LDAP.first_attribute(my_session,my_entry, my_ber_elmt);
    attr_index         := 1;
    WHILE my_attr_name IS NOT NULL
    LOOP
      my_vals         := DBMS_LDAP.get_values (my_session, my_entry, my_attr_name);
      IF my_vals.COUNT > 0 THEN
        FOR i IN my_vals.FIRST..my_vals.LAST
        LOOP
          DBMS_OUTPUT.PUT_LINE('           ' || my_attr_name || ' : ' || SUBSTR(my_vals(i),1,200));
        END LOOP;
      END IF;
      my_attr_name := DBMS_LDAP.next_attribute(my_session,my_entry, my_ber_elmt);
      attr_index   := attr_index+1;
    END LOOP;
    my_entry := DBMS_LDAP.next_entry(my_session, my_entry);
    DBMS_OUTPUT.PUT_LINE('===================================================');
    entry_index := entry_index+1;
  END LOOP;
  -- unbind from the directory
  retval := DBMS_LDAP.unbind_s(my_session);
  DBMS_OUTPUT.PUT_LINE(RPAD('unbind_res Returns ',25,' ') || ': ' || TO_CHAR(retval));
  DBMS_OUTPUT.PUT_LINE('Directory operation Successful .. exiting'); -- Handle Exceptions
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE(' Error code    : ' || TO_CHAR(SQLCODE));
  DBMS_OUTPUT.PUT_LINE(' Error Message : ' || SQLERRM);
  DBMS_OUTPUT.PUT_LINE(' Exception encountered .. exiting');
END;
/

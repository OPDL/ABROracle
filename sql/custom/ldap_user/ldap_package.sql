-- LDAP Access Package
-- Author: Adam Richards
CREATE OR REPLACE PACKAGE abrldap
  -- Author: Adam Richards
AS
  FUNCTION getUserGroups(
      sam VARCHAR2)
    RETURN INTEGER;
  FUNCTION getUserGroups2(
      sam VARCHAR2)
    RETURN INTEGER;
END abrldap;
/
CREATE OR REPLACE PACKAGE BODY abrldap
IS
  -- Author: Adam Richards
FUNCTION getUserGroups(
    sam VARCHAR2)
  RETURN INTEGER
IS
  l_ldap_host   VARCHAR2(256) := 'mcp.epc.com';
  l_ldap_port   VARCHAR2(256) := '389';
  l_ldap_user   VARCHAR2(256) := 'epc\AppAsrRBD';
  l_ldap_passwd VARCHAR2(256) := 'Nxr7WRB3';
  l_ldap_base   VARCHAR2(256) := 'dc=epc,dc=com';
  l_retval PLS_INTEGER;
  l_session DBMS_LDAP.session;
  l_attrs DBMS_LDAP.string_collection;
  l_message DBMS_LDAP.message;
  l_entry DBMS_LDAP.message;
  l_vals DBMS_LDAP.string_collection;
  l_attr_name VARCHAR2(256);
  l_ber_element DBMS_LDAP.ber_element;
BEGIN
  DBMS_LDAP.USE_EXCEPTION   := TRUE;
  DBMS_LDAP.UTF8_CONVERSION := FALSE;
  --
  l_session := DBMS_LDAP.init( hostname => l_ldap_host, portnum => l_ldap_port );
  l_retval  := DBMS_LDAP.simple_bind_s( ld => l_session, dn => l_ldap_user, passwd => l_ldap_passwd );
  -- search memberOF Attribute
  l_attrs(0) := 'memberOf';
  l_retval   := DBMS_LDAP.search_s ( ld => l_session, base => l_ldap_base, scope => DBMS_LDAP.SCOPE_SUBTREE, filter => '(samAccountName=' || sam || ')', attrs => l_attrs, attronly => 0, res => l_message);
  l_retval   := DBMS_LDAP.count_entries(ld => l_session, msg => l_message);
  IF l_retval > 0 THEN
    l_entry  := DBMS_LDAP.first_entry(ld => l_session, msg => l_message);
    << entry_loop >>
    WHILE l_entry IS NOT NULL
    LOOP
      l_attr_name := DBMS_LDAP.first_attribute(ld => l_session, ldapentry => l_entry, ber_elem => l_ber_element);
      << attributes_loop >>
      WHILE l_attr_name IS NOT NULL
      LOOP
        l_vals := DBMS_LDAP.get_values (ld => l_session, ldapentry => l_entry, attr => l_attr_name);
        << values_loop >>
        FOR i IN l_vals.FIRST .. l_vals.LAST
        LOOP
          DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || l_attr_name || ' = ' || SUBSTR(l_vals(i),1,200));
        END LOOP values_loop;
        l_attr_name := DBMS_LDAP.next_attribute(ld => l_session, ldapentry => l_entry, ber_elem => l_ber_element);
      END LOOP attibutes_loop;
      l_entry := DBMS_LDAP.next_entry(ld => l_session, msg => l_entry);
    END LOOP entry_loop;
  END IF;
  l_retval := DBMS_LDAP.unbind_s(ld => l_session);
  RETURN 0;
END getUserGroups;
FUNCTION getUserGroups2(
    sam VARCHAR2)
  RETURN INTEGER
IS
  ldap_host VARCHAR2(256);
  ldap_port PLS_INTEGER;
  ldap_user   VARCHAR2(256);
  ldap_passwd VARCHAR2(256);
  ldap_base   VARCHAR2(256);
  retval PLS_INTEGER;
  my_session DBMS_LDAP.session;
  my_pset_coll DBMS_LDAP_UTL.PROPERTY_SET_COLLECTION;
  my_property_names DBMS_LDAP.STRING_COLLECTION;
  my_property_values DBMS_LDAP.STRING_COLLECTION;
  user_handle DBMS_LDAP_UTL.HANDLE;
  user_id  VARCHAR2(2000);
  group_id VARCHAR2(2000);
  user_type PLS_INTEGER;
  group_type PLS_INTEGER;
  group_handle DBMS_LDAP_UTL.HANDLE;
BEGIN
  ldap_host   := 'mcp.epc.com';
  ldap_port   := 389;
  ldap_user   := 'epc\';
  ldap_passwd := '';
  ldap_base   := 'dc=epc,dc=com';
  user_type   := DBMS_LDAP_UTL.TYPE_DN;
  group_type  := DBMS_LDAP_UTL.TYPE_DN;
  user_id     := 'user_or_group_dn';
  group_id    := 'group_dn';
  -- Choosing exceptions to be raised by DBMS_LDAP library.
  DBMS_LDAP.USE_EXCEPTION := TRUE;
  my_session := DBMS_LDAP.init(ldap_host,ldap_port);
  retval := DBMS_LDAP.simple_bind_s(my_session, ldap_user, ldap_passwd);
  retval    := DBMS_LDAP_UTL.create_user_handle(user_handle,user_type,user_id);
  IF retval != DBMS_LDAP_UTL.SUCCESS THEN
    -- Handle Errors
    DBMS_OUTPUT.PUT_LINE('create_user_handle returns : ' || TO_CHAR(retval));
  END IF;
  ---------------------------------------------------------------------
  -- Create group_handle Handle
  --
  ---------------------------------------------------------------------
  retval    := DBMS_LDAP_UTL.create_group_handle(group_handle,group_type,group_id);
  IF retval != DBMS_LDAP_UTL.SUCCESS THEN
    -- Handle Errors
    DBMS_OUTPUT.PUT_LINE('create_group_handle returns : ' || TO_CHAR(retval));
  END IF;
  ---------------------------------------
  -- Check Group Membership
  --
  ---------------------------------------
  retval := DBMS_LDAP_UTL.check_group_membership( my_session, user_handle, group_handle,
  /*DBMS_LDAP_UTL.DIRECT_MEMBERSHIP*/
  DBMS_LDAP_UTL.NESTED_MEMBERSHIP);
  IF retval != DBMS_LDAP_UTL.SUCCESS THEN
    DBMS_OUTPUT.PUT_LINE('get_group_membership returns : Not member');
  ELSE
    DBMS_OUTPUT.PUT_LINE('get_group_membership returns : Member');
  END IF;
  
  DBMS_LDAP_UTL.free_handle(user_handle);
  DBMS_LDAP_UTL.free_handle(group_handle);
  
  retval    := DBMS_LDAP.unbind_s(my_session);
  IF retval != DBMS_LDAP_UTL.SUCCESS THEN
    -- Handle Errors
    DBMS_OUTPUT.PUT_LINE('unbind_s returns : ' || TO_CHAR(retval));
  END IF;
  -- Handle Exceptions
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE(' Error code : ' || TO_CHAR(SQLCODE));
  DBMS_OUTPUT.PUT_LINE(' Error Message : ' || SQLERRM);
  DBMS_OUTPUT.PUT_LINE(' Exception encountered .. exiting');
END getUserGroups2;
END abrldap;
/
-- TEST
SET serveroutput ON
SELECT abrldap.getUserGroups('dsvrichards') FROM dual;
/
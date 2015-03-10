CREATE OR REPLACE PACKAGE abrldap
  -- LDAP Access Package
  -- Author: Adam Richards
AS
  FUNCTION getUserGroups(
      sam VARCHAR2)
    RETURN INTEGER;
  FUNCTION checkUserIsMemberOf(
      sam       VARCHAR2,
      groupName VARCHAR2 )
    RETURN INTEGER;
END abrldap;
/
CREATE OR REPLACE PACKAGE BODY abrldap
IS
  -- Author: Adam Richards
  -- private constants
  LDAP_HOST    CONSTANT VARCHAR2(256) := 'mcp.epc.com';
  LDAP_PORT    CONSTANT VARCHAR2(256) := '389';
  LDAP_USER    CONSTANT VARCHAR2(256) := 'epc\AppAsrRBD';
  LDAP_USER_PW CONSTANT VARCHAR2(256) := 'Nxr7WRB3';
  LDAP_BASE    CONSTANT VARCHAR2(256) := 'dc=epc,dc=com';
FUNCTION getUserGroups(
    sam VARCHAR2)
  RETURN INTEGER
IS
  l_ldap_host   VARCHAR2(256) := LDAP_HOST;
  l_ldap_port   VARCHAR2(256) := LDAP_PORT;
  l_ldap_user   VARCHAR2(256) := LDAP_USER;
  l_ldap_passwd VARCHAR2(256) := LDAP_USER_PW;
  l_ldap_base   VARCHAR2(256) := LDAP_BASE;
  l_retval PLS_INTEGER;
  l_session DBMS_LDAP.session;
  l_attrs DBMS_LDAP.string_collection;
  l_message DBMS_LDAP.message;
  l_entry DBMS_LDAP.message;
  l_vals DBMS_LDAP.string_collection;
  p_vals DBMS_LDAP.string_collection;
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
          DBMS_OUTPUT.PUT_LINE(l_vals(i));
          p_vals    := DBMS_LDAP.explode_dn(dn => l_vals(i), notypes => 0);
          IF p_vals IS NOT NULL THEN
            << dn_loop >>
            FOR z IN p_vals.FIRST .. p_vals.LAST
            LOOP
              DBMS_OUTPUT.PUT_LINE('E: ' || p_vals(z));
            END LOOP;
          END IF;
        END LOOP values_loop;
        l_attr_name := DBMS_LDAP.next_attribute(ld => l_session, ldapentry => l_entry, ber_elem => l_ber_element);
      END LOOP attibutes_loop;
      l_entry := DBMS_LDAP.next_entry(ld => l_session, msg => l_entry);
    END LOOP entry_loop;
  END IF;
  l_retval := DBMS_LDAP.unbind_s(ld => l_session);
  RETURN 0;
END getUserGroups;
FUNCTION checkUserIsMemberOf(
    sam       VARCHAR2,
    groupName VARCHAR2 )
  RETURN INTEGER
IS
  l_ldap_host   VARCHAR2(256) := LDAP_HOST;
  l_ldap_port   VARCHAR2(256) := LDAP_PORT;
  l_ldap_user   VARCHAR2(256) := LDAP_USER;
  l_ldap_passwd VARCHAR2(256) := LDAP_USER_PW;
  l_ldap_base   VARCHAR2(256) := LDAP_BASE;
  l_retval PLS_INTEGER;
  l_session DBMS_LDAP.session;
  l_attrs DBMS_LDAP.string_collection;
  l_message DBMS_LDAP.message;
  l_entry DBMS_LDAP.message;
  l_vals DBMS_LDAP.string_collection;
  p_vals DBMS_LDAP.string_collection;
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
          DBMS_OUTPUT.PUT_LINE(l_vals(i));
          if upper(l_vals(i)) = upper(groupName) then
              l_retval := DBMS_LDAP.unbind_s(ld => l_session);
              return 0;
            end if;
          p_vals    := DBMS_LDAP.explode_dn(dn => l_vals(i), notypes => 1);
          IF p_vals IS NOT NULL THEN
            << dn_loop >>
            FOR z IN p_vals.FIRST .. p_vals.LAST
            LOOP
              DBMS_OUTPUT.PUT_LINE('E: ' || p_vals(z));
            END LOOP;
            if upper(p_vals(0)) = upper(groupName) then
              l_retval := DBMS_LDAP.unbind_s(ld => l_session);
              return 0;
            end if;
          END IF;
          
        END LOOP values_loop;
        l_attr_name := DBMS_LDAP.next_attribute(ld => l_session, ldapentry => l_entry, ber_elem => l_ber_element);
      END LOOP attibutes_loop;
      l_entry := DBMS_LDAP.next_entry(ld => l_session, msg => l_entry);
    END LOOP entry_loop;
  END IF;
  l_retval := DBMS_LDAP.unbind_s(ld => l_session);
  RETURN 1;
END checkUserIsMemberOf;
END abrldap;
/
-- TEST
SET serveroutput ON
SELECT abrldap.getUserGroups('dsvrichards') FROM dual;
/
SELECT abrldap.checkUserIsMemberOf('dsvrichards','CN=VPN Access,CN=Users,DC=epc,DC=com')
FROM dual;
/
SELECT abrldap.checkUserIsMemberOf('dsvrichards','VPN Access')
FROM dual;
/

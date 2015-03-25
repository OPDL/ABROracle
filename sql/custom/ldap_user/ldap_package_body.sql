create or replace PACKAGE BODY abrldap
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
          IF upper(l_vals(i)) = upper(groupName) THEN
            l_retval         := DBMS_LDAP.unbind_s(ld => l_session);
            RETURN 0;
          END IF;
          p_vals    := DBMS_LDAP.explode_dn(dn => l_vals(i), notypes => 1);
          IF p_vals IS NOT NULL THEN
            << dn_loop >>
            FOR z IN p_vals.FIRST .. p_vals.LAST
            LOOP
              DBMS_OUTPUT.PUT_LINE('E: ' || p_vals(z));
            END LOOP;
            IF upper(p_vals(0)) = upper(groupName) THEN
              l_retval         := DBMS_LDAP.unbind_s(ld => l_session);
              RETURN 0;
            END IF;
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
FUNCTION getOrgUnits
  RETURN dn_table PIPELINED
IS
  i PLS_INTEGER;
  attr_index PLS_INTEGER;
  entry_index PLS_INTEGER;
  l_dn        VARCHAR2(256);
  l_attr_name VARCHAR2(256);
  l_name      VARCHAR2(256);
  l_retval PLS_INTEGER;
  l_session DBMS_LDAP.session;
  l_attrs DBMS_LDAP.string_collection;
  l_message DBMS_LDAP.message;
  l_entry DBMS_LDAP.message;
  l_vals DBMS_LDAP.string_collection;
  p_vals DBMS_LDAP.string_collection;
  l_ber_element DBMS_LDAP.ber_element;
  objectClass VARCHAR2(256) := 'organizationalUnit';
  rec dn_record;
BEGIN
  DBMS_LDAP.USE_EXCEPTION   := TRUE;
  DBMS_LDAP.UTF8_CONVERSION := FALSE;
  l_session                 := DBMS_LDAP.init(LDAP_HOST,LDAP_PORT);
  DBMS_OUTPUT.PUT_LINE (RPAD('Ldap session ',25,' ') || ': ' || RAWTOHEX(SUBSTR(l_session,1,8)) || '(returned from init)');
  -- bind to the directory
  l_retval := DBMS_LDAP.simple_bind_s(l_session, LDAP_USER, LDAP_USER_PW);
  DBMS_OUTPUT.PUT_LINE(RPAD('simple_bind_s Returns ',25,' ') || ': ' || TO_CHAR(l_retval));
  -- issue the search
  -- l_attrs(1) := '*'; -- retrieve all attributes
  l_attrs(1) := 'DN'; -- just get DN
  -- DBMS_LDAP.SCOPE_ONELEVEL
  l_retval := DBMS_LDAP.search_s(l_session, LDAP_BASE, DBMS_LDAP.SCOPE_SUBTREE, '(objectclass=' || objectClass || ')', l_attrs, 0, l_message);
  DBMS_OUTPUT.PUT_LINE(RPAD('search_s Returns ',25,' ') || ': ' || TO_CHAR(l_retval));
  DBMS_OUTPUT.PUT_LINE (RPAD('LDAP message  ',25,' ') || ': ' || RAWTOHEX(SUBSTR(l_message,1,8)) || '(returned from search_s)');
  -- count the number of entries returned
  l_retval := DBMS_LDAP.count_entries(l_session, l_message);
  DBMS_OUTPUT.PUT_LINE(RPAD('Number of Entries ',25,' ') || ': ' || TO_CHAR(l_retval));
  
  -- get the first entry
  l_entry     := DBMS_LDAP.first_entry(l_session, l_message);
  entry_index := 1;
  -- Loop through each of the entries one by one
  WHILE l_entry IS NOT NULL
  LOOP
    attr_index := 1;
    -- print the current entry
    l_dn := DBMS_LDAP.get_dn(l_session, l_entry);
    -- DBMS_OUTPUT.PUT_LINE ('        entry #' || TO_CHAR(entry_index) ||
    -- ' entry ptr: ' || RAWTOHEX(SUBSTR(l_entry,1,8)));
    -- DBMS_OUTPUT.PUT_LINE ('        dn: ' || l_dn);
    l_name    := NULL;
    p_vals    := DBMS_LDAP.explode_dn(dn => l_dn, notypes => 1);
    IF p_vals IS NOT NULL THEN
      l_name  := p_vals(0);
    END IF;
    SELECT entry_index, LDAP_HOST, LDAP_BASE, l_dn,l_name INTO rec FROM DUAL;
    PIPE ROW (rec);
    l_attr_name       := DBMS_LDAP.first_attribute(l_session,l_entry, l_ber_element);
    WHILE l_attr_name IS NOT NULL
    LOOP
      l_vals         := DBMS_LDAP.get_values (l_session, l_entry, l_attr_name);
      IF l_vals.COUNT > 0 THEN
        FOR i IN l_vals.FIRST..l_vals.LAST
        LOOP
          SELECT entry_index,
            'a',
            'bar',
            'baz',
            'v'
          INTO rec
          FROM DUAL;
          PIPE ROW (rec);
          
        END LOOP;
      END IF;
      l_attr_name := DBMS_LDAP.next_attribute(l_session,l_entry, l_ber_element);
      attr_index  := attr_index+1;
    END LOOP;
    l_entry := DBMS_LDAP.next_entry(l_session, l_entry);
   
    entry_index := entry_index+1;
  END LOOP;
  l_retval := DBMS_LDAP.unbind_s(l_session);
  RETURN;
END getOrgUnits;
FUNCTION getGroupsByOU
  RETURN dn_table PIPELINED
IS
  i PLS_INTEGER;
  attr_index PLS_INTEGER;
  entry_index PLS_INTEGER;
  l_dn        VARCHAR2(256);
  l_attr_name VARCHAR2(256);
  l_name      VARCHAR2(256);
  l_base      VARCHAR2(500);
  l_retval PLS_INTEGER;
  l_session DBMS_LDAP.session;
  l_attrs DBMS_LDAP.string_collection;
  l_message DBMS_LDAP.message;
  l_entry DBMS_LDAP.message;
  l_vals DBMS_LDAP.string_collection;
  p_vals DBMS_LDAP.string_collection;
  l_ber_element DBMS_LDAP.ber_element;
  objectClass VARCHAR2(256) := 'group';
  rec dn_record;
  org_unit_rec dn_record;
BEGIN
  DBMS_LDAP.USE_EXCEPTION   := TRUE;
  DBMS_LDAP.UTF8_CONVERSION := FALSE;
  l_session                 := DBMS_LDAP.init(LDAP_HOST,LDAP_PORT);
  DBMS_OUTPUT.PUT_LINE (RPAD('Ldap session ',25,' ') || ': ' || RAWTOHEX(SUBSTR(l_session,1,8)) || '(returned from init)');
  -- bind to the directory
  l_retval := DBMS_LDAP.simple_bind_s(l_session, LDAP_USER, LDAP_USER_PW);
  DBMS_OUTPUT.PUT_LINE(RPAD('simple_bind_s Returns ',25,' ') || ': ' || TO_CHAR(l_retval));
  -- issue the search
  -- l_attrs(1) := '*'; -- retrieve all attributes
  l_attrs(1) := 'DN'; -- just get DN
  -- DBMS_LDAP.SCOPE_ONELEVEL
  entry_index := 1;
  FOR org_unit_rec IN
  ( SELECT * FROM TABLE(getOrgUnits) ORDER BY dn
  )
  LOOP
    l_base   := org_unit_rec.dn;
    l_retval := DBMS_LDAP.search_s(l_session, l_base, DBMS_LDAP.SCOPE_SUBTREE, '(objectclass=' || objectClass || ')', l_attrs, 0, l_message);
    -- DBMS_OUTPUT.PUT_LINE(RPAD('Search Return Value: ',25,' ') || ': ' || TO_CHAR(l_retval));
    -- DBMS_OUTPUT.PUT_LINE (RPAD('LDAP message:  ',25,' ') || ': ' || RAWTOHEX(SUBSTR(l_message,1,8)) || '(returned from search_s)');
    -- count the number of entries returned
    l_retval := DBMS_LDAP.count_entries(l_session, l_message);
    DBMS_OUTPUT.PUT_LINE(RPAD('Number of Entries ',25,' ') || ': ' || l_base || ':' || objectClass || ':' || TO_CHAR(l_retval));
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------');
    -- get the first entry
    l_entry := DBMS_LDAP.first_entry(l_session, l_message);
    -- Loop through each of the entries one by one
    WHILE l_entry IS NOT NULL
    LOOP
      attr_index := 1;
      -- print the current entry
      l_dn := DBMS_LDAP.get_dn(l_session, l_entry);
      -- DBMS_OUTPUT.PUT_LINE ('        entry #' || TO_CHAR(entry_index) ||
      -- ' entry ptr: ' || RAWTOHEX(SUBSTR(l_entry,1,8)));
      DBMS_OUTPUT.PUT_LINE ('        dn: ' || l_dn);
      l_name    := NULL;
      p_vals    := DBMS_LDAP.explode_dn(dn => l_dn, notypes => 1);
      IF p_vals IS NOT NULL THEN
        l_name  := p_vals(0);
      END IF;
      SELECT entry_index, LDAP_HOST, l_base, l_dn,l_name INTO rec FROM DUAL;
      PIPE ROW (rec);
      l_attr_name       := DBMS_LDAP.first_attribute(l_session,l_entry, l_ber_element);
      WHILE l_attr_name IS NOT NULL
      LOOP
        l_vals         := DBMS_LDAP.get_values (l_session, l_entry, l_attr_name);
        IF l_vals.COUNT > 0 THEN
          FOR i IN l_vals.FIRST..l_vals.LAST
          LOOP
            SELECT entry_index,
              'a',
              'bar',
              'baz',
              'v'
            INTO rec
            FROM DUAL;
            PIPE ROW (rec);
            DBMS_OUTPUT.PUT_LINE('           ' || l_attr_name || ' : ' || SUBSTR(l_vals(i),1,800));
          END LOOP;
        END IF;
        l_attr_name := DBMS_LDAP.next_attribute(l_session,l_entry, l_ber_element);
        attr_index  := attr_index+1;
      END LOOP;
      l_entry := DBMS_LDAP.next_entry(l_session, l_entry);
      DBMS_OUTPUT.PUT_LINE('===================================================');
      entry_index := entry_index+1;
    END LOOP;
  END LOOP;
  l_retval := DBMS_LDAP.unbind_s(l_session);
  RETURN;
END getGroupsByOU;
FUNCTION getUsersByOU
  RETURN u_table PIPELINED
IS
  i PLS_INTEGER;
  attr_index PLS_INTEGER;
  entry_index PLS_INTEGER;
  l_dn        VARCHAR2(256);
  l_attr_name VARCHAR2(256);
  l_name      VARCHAR2(256);
  l_base      VARCHAR2(500);
  l_retval PLS_INTEGER;
  l_session DBMS_LDAP.session;
  l_attrs DBMS_LDAP.string_collection;
  l_message DBMS_LDAP.message;
  l_entry DBMS_LDAP.message;
  l_vals DBMS_LDAP.string_collection;
  p_vals DBMS_LDAP.string_collection;
  l_ber_element DBMS_LDAP.ber_element;
  rec u_record;
  org_unit_rec dn_record;
  
  l_filter      VARCHAR2(500);
  type array_c IS TABLE OF VARCHAR2(1);
  letter_list array_c:=array_c();
  
  type assoc_arr is table of varchar2(4000) index by varchar2(100);
  value_list assoc_arr;
BEGIN
  DBMS_LDAP.USE_EXCEPTION   := TRUE;
  DBMS_LDAP.UTF8_CONVERSION := FALSE;
  -- populate list of alphabet chars
  FOR q IN 1 .. 26
  LOOP
    letter_list.extend(1);
    letter_list(q) := chr(64+q);
  END LOOP;
  l_session   := DBMS_LDAP.init(LDAP_HOST,LDAP_PORT);
  l_retval    := DBMS_LDAP.simple_bind_s(l_session, LDAP_USER, LDAP_USER_PW);
  
  l_attrs(0)  := 'givenname';
  l_attrs(1)  := 'sn';
  l_attrs(2)  := 'cn';
  l_attrs(3)  := 'samaccountname';
  l_attrs(4)  := 'mail';
  l_attrs(5)  := 'manager';
  l_attrs(6)  := 'telephoneNumber';
  l_attrs(7)  := 'lastLogonTimestamp';
  l_attrs(8)  := 'userAccountControl';
  l_attrs(9)  := 'physicalDeliveryOfficeName';
  l_attrs(10)  := 'department';
  l_attrs(11)  := 'company';
  l_attrs(11)  := 'employeeID';
  
  entry_index := 1;
  FOR org_unit_rec IN
  ( SELECT * FROM TABLE(getOrgUnits) ORDER BY dn
  )
  LOOP
    l_base := org_unit_rec.dn;
    FOR z IN letter_list.FIRST .. letter_list.LAST
    LOOP
      l_filter :=  '(&(objectclass=user)(!(objectclass=computer))(sn=' || letter_list(z) || '*))';
      l_message := null;
    
      l_retval := DBMS_LDAP.search_s(l_session, l_base, DBMS_LDAP.SCOPE_SUBTREE,l_filter, l_attrs, 0, l_message);
      l_retval := DBMS_LDAP.count_entries(l_session, l_message);
      DBMS_OUTPUT.PUT_LINE('NumRecs: ' || l_base || ':' || letter_list(z) || ': ' || ': ' || TO_CHAR(l_retval));
      -- get the first entry
      l_entry := DBMS_LDAP.first_entry(l_session, l_message);
      -- Loop through each of the entries one by one
      WHILE l_entry IS NOT NULL
      LOOP
        value_list.delete();
        attr_index := 1;
        l_dn       := DBMS_LDAP.get_dn(l_session, l_entry);
        -- DBMS_OUTPUT.PUT_LINE ('dn:' || l_dn);
        l_name    := NULL;
        p_vals    := DBMS_LDAP.explode_dn(dn => l_dn, notypes => 1);
        IF p_vals IS NOT NULL THEN
          l_name  := p_vals(0);
        END IF;
    
        l_attr_name       := DBMS_LDAP.first_attribute(l_session,l_entry, l_ber_element);
        WHILE l_attr_name IS NOT NULL
        LOOP
          l_vals         := DBMS_LDAP.get_values (l_session, l_entry, l_attr_name);

          IF l_vals.COUNT > 0 THEN
        
          
            FOR i IN l_vals.FIRST..l_vals.LAST
             LOOP
             if i=0 then
             value_list(l_attr_name) := trim(both ' ' FROM l_vals(i));
             else
             value_list(l_attr_name) := value_list(l_attr_name) || '|' || trim(both ' ' FROM l_vals(i));
             end if;
              DBMS_OUTPUT.PUT_LINE(to_char(attr_index) || ':' || to_char(i) || ':' ||  l_attr_name || ' : ' || trim(both ' ' FROM l_vals(i)));
            END LOOP;
         
          END IF;
         
          l_attr_name := DBMS_LDAP.next_attribute(l_session,l_entry, l_ber_element);
          attr_index  := attr_index+1;
        END LOOP;
        if value_list.exists('givenName') = false         then           value_list('givenName') := NULL;         end if;
        if value_list.exists('sn') = false         then           value_list('sn') := NULL;         end if;
        if value_list.exists('cn') = false         then           value_list('cn') := NULL;         end if;
        if value_list.exists('sAMAccountName') = false         then           value_list('sAMAccountName') := NULL;         end if;
        if value_list.exists('mail') = false         then           value_list('mail') := NULL;         end if;
        if value_list.exists('manager') = false         then           value_list('manager') := NULL;         end if;
        if value_list.exists('telephoneNumber') = false         then           value_list('telephoneNumber') := NULL;         end if;
        if value_list.exists('lastLogonTimestamp') = false         then           value_list('lastLogonTimestamp') := NULL;         end if;
        if value_list.exists('physicalDeliveryOfficeName') = false         then           value_list('physicalDeliveryOfficeName') := NULL;         end if;
        if value_list.exists('department') = false         then           value_list('department') := NULL;         end if;
        if value_list.exists('company') = false         then           value_list('company') := NULL;         end if;
        if value_list.exists('employeeID') = false         then           value_list('employeeID') := NULL;         end if;
        
        value_list('disabled') := bitand(2,value_list('userAccountControl'))/2;
        --   id, server, base, dn, first_name, last_name, common_name, sam, email, phone,manager 
         SELECT entry_index,LDAP_HOST,l_base,l_dn
         ,value_list('employeeID')
         ,value_list('givenName')
         ,value_list('sn')
         ,value_list('cn')
         ,value_list('sAMAccountName')
         ,value_list('mail')
         ,value_list('telephoneNumber')
         ,value_list('manager')
         ,value_list('company')
         ,value_list('department')
         ,value_list('physicalDeliveryOfficeName')
         ,to_date('01-01-1601', 'MM-DD-YYYY') 
                +       (
                                value_list('lastLogonTimestamp')      /* nano seconds */
                        *       (100/power(10,9))         /* Seconds per nanosecond */
                        *       (1/60)                  /* Minutes per second */
                        *       (1/60)                  /* hours per minute */
                        *       (1/24)                  /* days per hour */
                        )
         ,to_number(value_list('disabled'))
        
         INTO rec FROM DUAL;
         PIPE ROW(rec);
        l_entry := DBMS_LDAP.next_entry(l_session, l_entry);
        entry_index := entry_index+1;
      END LOOP;
    END LOOP;
  END LOOP;
  l_retval := DBMS_LDAP.unbind_s(l_session);
  RETURN;
  EXCEPTION
   WHEN OTHERS THEN
      l_retval := DBMS_LDAP.unbind_s(l_session);
      raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM|| DBMS_UTILITY.format_error_backtrace);
END getUsersByOU;

FUNCTION getUserMemberOfByOU
  RETURN m_table PIPELINED
IS
  i PLS_INTEGER;
  attr_index PLS_INTEGER;
  entry_index PLS_INTEGER;
  l_dn        VARCHAR2(256);
  l_attr_name VARCHAR2(256);
  l_name      VARCHAR2(256);
  l_base      VARCHAR2(500);
  l_retval PLS_INTEGER;
  l_session DBMS_LDAP.session;
  l_attrs DBMS_LDAP.string_collection;
  l_message DBMS_LDAP.message;
  l_entry DBMS_LDAP.message;
  l_vals DBMS_LDAP.string_collection;
  p_vals DBMS_LDAP.string_collection;
  l_ber_element DBMS_LDAP.ber_element;
  rec m_record;
  org_unit_rec dn_record;
  
  l_filter      VARCHAR2(500);
  type array_c IS TABLE OF VARCHAR2(1);
  letter_list array_c:=array_c();
  
  type assoc_arr is table of varchar2(4000) index by varchar2(100);
  value_list assoc_arr;
BEGIN
  DBMS_LDAP.USE_EXCEPTION   := TRUE;
  DBMS_LDAP.UTF8_CONVERSION := FALSE;
  -- populate list of alphabet chars
  FOR q IN 1 .. 26
  LOOP
    letter_list.extend(1);
    letter_list(q) := chr(64+q);
  END LOOP;
  l_session   := DBMS_LDAP.init(LDAP_HOST,LDAP_PORT);
  l_retval    := DBMS_LDAP.simple_bind_s(l_session, LDAP_USER, LDAP_USER_PW);
  
  l_attrs(0)  := 'samaccountname';
  l_attrs(1)  := 'memberof';
  
  entry_index := 1;
  FOR org_unit_rec IN
  ( SELECT * FROM TABLE(getOrgUnits) ORDER BY dn
  )
  LOOP
    l_base := org_unit_rec.dn;
    FOR z IN letter_list.FIRST .. letter_list.LAST
    LOOP
      l_filter :=  '(&(objectclass=user)(!(objectclass=computer))(sn=' || letter_list(z) || '*))';
      l_message := null;
    
      l_retval := DBMS_LDAP.search_s(l_session, l_base, DBMS_LDAP.SCOPE_SUBTREE,l_filter, l_attrs, 0, l_message);
      l_retval := DBMS_LDAP.count_entries(l_session, l_message);
      DBMS_OUTPUT.PUT_LINE('NumRecs: ' || l_base || ':' || letter_list(z) || ': ' || ': ' || TO_CHAR(l_retval));
      -- get the first entry
      l_entry := DBMS_LDAP.first_entry(l_session, l_message);
      -- Loop through each of the entries one by one
      WHILE l_entry IS NOT NULL
      LOOP
        value_list.delete();
        
        l_dn       := DBMS_LDAP.get_dn(l_session, l_entry);
        -- DBMS_OUTPUT.PUT_LINE ('dn:' || l_dn);
        l_name    := NULL;
        p_vals    := DBMS_LDAP.explode_dn(dn => l_dn, notypes => 1);
        IF p_vals IS NOT NULL THEN
          l_name  := p_vals(0);
        END IF;
    -- loop through all attr to make sure we get samaccountname first
      attr_index := 1;
      l_attr_name       := DBMS_LDAP.first_attribute(l_session,l_entry, l_ber_element);
      WHILE l_attr_name IS NOT NULL
      LOOP
        l_vals         := DBMS_LDAP.get_values (l_session, l_entry, l_attr_name);
        IF l_vals.COUNT > 0 THEN
          FOR i IN l_vals.FIRST..l_vals.LAST
          LOOP
          -- get just first value fro attr if more than one
            IF i                       =0 THEN
              value_list(l_attr_name) := trim(both ' ' FROM l_vals(i));
            END IF;
          END LOOP;
        END IF;
        l_attr_name := DBMS_LDAP.next_attribute(l_session,l_entry, l_ber_element);
        attr_index  := attr_index+1;
      END LOOP;
      
      -- loop again and get any member of
      attr_index := 1;
      l_attr_name       := DBMS_LDAP.first_attribute(l_session,l_entry, l_ber_element);
      WHILE l_attr_name IS NOT NULL
      LOOP
        l_vals         := DBMS_LDAP.get_values (l_session, l_entry, l_attr_name);
        IF l_vals.COUNT > 0 THEN
          FOR i IN l_vals.FIRST..l_vals.LAST
          LOOP
            
            IF upper(l_attr_name) = 'MEMBEROF' THEN
            SELECT entry_index,LDAP_HOST,l_base,l_dn ,
              value_list('sAMAccountName') ,
              trim(both ' ' FROM l_vals(i)) INTO rec FROM DUAL;
            PIPE ROW(rec);
            END IF;
            DBMS_OUTPUT.PUT_LINE(TO_CHAR(attr_index) || ':' || TO_CHAR(i) || ':' || l_attr_name || ' : ' || trim(both ' ' FROM l_vals(i)));
          END LOOP;
        END IF;
        l_attr_name := DBMS_LDAP.next_attribute(l_session,l_entry, l_ber_element);
        attr_index  := attr_index+1;
      END LOOP;
      
        l_entry := DBMS_LDAP.next_entry(l_session, l_entry);
        entry_index := entry_index+1;
      END LOOP;
    END LOOP;
  END LOOP;
  l_retval := DBMS_LDAP.unbind_s(l_session);
  RETURN;
  EXCEPTION
   WHEN OTHERS THEN
      l_retval := DBMS_LDAP.unbind_s(l_session);
      raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM|| DBMS_UTILITY.format_error_backtrace);
END getUserMemberOfByOU;

END abrldap;

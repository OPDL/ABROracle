#!/bin/bash
read -p "Enter your EPC username (ex: dsvsmith ): " UN
printf "Enter LDAP Password: "
ldapsearch -E pr=1000/noprompt -h mcp.epc.com -p 389 -D "${UN}@epc.com" -x -W -b "dc=epc,dc=com" "(&(objectclass=user)(!(objectclass=computer))(!(userAccountControl:1.2.840.113556.1.4.803:=2))(employeeID=*))" DN givenName sn sAMAccountName sAMAccountType displayName employeeID | grep -i -e 'displayName\|givenName\|sn\|employeeid\|samaccountname' > /tmp/xreflist


cat /tmp/xreflist | perl -ne 'if (m/(sAMAccountName[:]{1,2} .*)/) {print $1."\n";} else { if (m/(\w+[:]{1,2} .*)/) {print $1."," }}' |grep '::' > ADReport_encoded.csv

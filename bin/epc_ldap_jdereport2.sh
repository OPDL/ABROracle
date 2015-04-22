#!/bin/bash
read -p "Enter your EPC username (ex: dsvsmith ): " UN
printf "Enter LDAP Password: "
ldapsearch -E pr=1000/noprompt -h mcp.epc.com -p 389 -D "${UN}@epc.com" -x -W -b "dc=epc,dc=com" "(&(objectclass=user)(!(objectclass=computer))(!(userAccountControl:1.2.840.113556.1.4.803:=2))(employeeID=*))" DN givenName sn sAMAccountName sAMAccountType displayName employeeID | grep -i -e 'displayName\|givenName\|sn\|employeeid\|samaccountname' > /tmp/xreflist

cat /tmp/xreflist | perl -ne 'if (m/displayName[:]{1,2} (.*)/ || m/employeeID[:]{1,2} (.*)/ || m/sn[:]{1,2} (.*)/ || m/givenName[:]{1,2} (.*)/) {print $1.",";} else { if (m/sAMAccountName[:]{1,2} (.*)/) {print $1."\n";}}' | perl -pe '$_=uc($_);' > jdetable

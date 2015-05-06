#!/bin/bash
if [[ -z ${1} ]]; then
echo "Display Name argument required"
exit 1
fi
ldapsearch -LL -E pr=1000/noprompt -h mcp.epc.com -p 389 -D "un@xx.com" -x -w pw -b "dc=epc,dc=com" "(&(objectclass=user)(!(objectclass=computer))(!(userAccountControl:1.2.840.113556.1.4.803:=2))(DisplayName=${1}))" samaccountname | grep sAMAccountName: | sed -e 's/sAMAccountName: //ig'
#ldapsearch -LL -E pr=1000/noprompt -h mcp.epc.com -p 389 -D "un@xx.com" -x -w pw -b "dc=epc,dc=com" "(&(objectclass=user)(!(objectclass=computer))(!(memberof=CN=OU=SysAdmin,DC=epc,DC=com))(DisplayName=${1}))" samaccountname | grep sAMAccountName:
#ldapsearch -LL -E pr=1000/noprompt -h mcp.epc.com -p 389 -D "un@xx.com" -x -w pw -b "dc=epc,dc=com" "(&(objectclass=user)(!(objectclass=computer))(!(OU=Disabled Accounts))(DisplayName=${1}))" 
exit 0


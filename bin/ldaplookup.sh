#!/bin/bash
read -p "Enter username to find (ex: dsvsmith ): " LUN
read -p "Enter your EPC username (ex: dsvsmith ): " UN
ldapsearch -LL -E pr=1000/noprompt -h mcp.epc.com -p 389 -D "${UN}@epc.com" -x -W -b "dc=epc,dc=com" "(&(objectclass=user)(!(objectclass=computer))(samAccountName=${LUN}))"

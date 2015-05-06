-- set echo on
set serveroutput on
BEGIN
FOR u IN (
SELECT username
FROM dba_users
WHERE upper(username) like 'DSV_%'
AND
upper(username) not in
(
'SYS','SYSTEM','DBSNMP'
,'OUTLN','CTXSYS','EXFSYS'
,'XDB','ODMRSYS','WMSYS'
)
) 
LOOP
DBMS_OUTPUT.put_line(u.username);
EXECUTE IMMEDIATE 'GRANT ROLE_ASRLIST_RW TO ' || u.username;
EXECUTE IMMEDIATE 'ALTER USER ' || u.username || ' default role ALL';
END LOOP;
COMMIT;
END;
/


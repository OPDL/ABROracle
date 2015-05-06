pause Create KRONOS schema, run as sys (hit return to continue)

UNDEF SCHEMA
UNDEF PASSWORD

create user &&SCHEMA profile  APP_NO_EXPIRE_PW
identified by &&PASSWORD default tablespace TKCS3 temporary tablespace TEMP account unlock;

grant analyze any to &&SCHEMA;

grant connect, resource, drop public synonym, create
public synonym, create view to &&SCHEMA;

grant query rewrite to &&SCHEMA;

--Cross schema grants that will get  lost on import

grant select on dba_synonyms to &&SCHEMA;
grant select on v_$parameter to &&SCHEMA;
grant select on sys.dba_segments to &&SCHEMA;
grant select on sys.dba_tables to &&SCHEMA;
grant select on sys.dba_indexes to &&SCHEMA;
grant select on sys.dba_synonyms to &&SCHEMA;

--Grant CREATE DATABASE LINK for JDE views/db links, a local mod 
--will  come over from impdp...

UNDEF SCHEMA
UNDEF PASSWORD

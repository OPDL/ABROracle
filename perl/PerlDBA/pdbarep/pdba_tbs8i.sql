
-- pdba_tbs8i.sql
-- create tablespaces for PDBA repository
-- as Locally Managed Tablespaces

create tablespace pdba_data datafile '/u01/oradata/ts01/pdba_data_01.dbf' size 20m 
extent management local uniform size 128k
/

create tablespace pdba_idx datafile '/u01/oradata/ts01/pdba_idx_01.dbf' size 20m 
extent management local uniform size 128k
/



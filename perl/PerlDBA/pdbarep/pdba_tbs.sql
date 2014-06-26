

-- pdba_tbs.sql
-- create tablespaces for PDBA repository

create tablespace pdba_data datafile '/u01/oradata/ts01/pdba_data_01.dbf' size 20m
default storage ( initial 128k next 128k pctincrease 0 maxextents unlimited )
/

create tablespace pdba_idx datafile '/u01/oradata/ts01/pdba_idx_01.dbf' size 20m
default storage ( initial 128k next 128k pctincrease 0 maxextents unlimited )
/



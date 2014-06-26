
create user pdbarep identified by pdbarep
default tablespace pdba_data
temporary tablespace temp
/


alter user pdbarep quota unlimited on pdba_data;
alter user pdbarep quota unlimited on pdba_idx;


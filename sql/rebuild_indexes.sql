-- log in as schema of broken indexes
select 'alter index ' || owner || '.' || index_name ||' rebuild online;' from dba_indexes where status = 'UNUSABLE';
-- rebuild unusable indexes
select count(1) as unusable_cnt from user_indexes where status = 'UNUSABLE';
-- as owner schema
select 'alter index ' || index_name ||' rebuild online;' from user_indexes where status = 'UNUSABLE';

--CRPDTA:jdetest1 SQL> select 'alter index ' || index_name ||' rebuild online;' from user_indexes where status = 'UNUSABLE';
--no rows selected


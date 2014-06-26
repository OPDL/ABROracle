
-- index_frag_test.sql
-- index fragmentation test

spool index_frag_test.log

drop table idx_fragment;

prompt creating test table IDX_FRAGMENT

create table idx_fragment (
	pk number not null
	,testdata varchar2(2000)
)
/

prompt inserting test data into IDX_FRAGMENT

declare
	maxcount constant integer := 1000;
	insert_str varchar2(2000);
begin

	insert_str := rpad('X',1000,'X');

	for n in 1 .. maxcount
	loop
		insert into idx_fragment(pk,testdata )
		values(n, insert_str);
	end loop;
	commit;

end;
/

prompt creating primary key IDX_FRAGMENT_PK

alter table idx_fragment add constraint idx_fragment_pk
primary key(pk)
/

prompt creating index IDX_FRAGMENT_IDX

create index idx_fragment_idx
on idx_fragment( testdata, pk )
pctfree 0 
/

col segment_name format a30 head 'SEGMENT NAME'
col extent_id format a10 head 'EXTENT ID'
col bytes format 999,999,999 head 'BYTES'
compute sum of bytes on report
break on report

-- show number of extents 

select
	segment_name,
	decode(extent_id,0,'0',to_char(extent_id)) extent_id,
	bytes
from dba_extents
where owner = USER
and segment_name = 'IDX_FRAGMENT_IDX'
order by tablespace_name, segment_type, segment_name
/

-- number of rows in table
select count(*) IDX_FRAGMENT_ROW_COUNT from idx_fragment;

prompt delete every 5th row from the table and reinsert it

declare
	maxcount constant integer := 1000;
	insert_str varchar2(2000);
begin
	insert_str := rpad('X',1000,'X');
	for n in 1 .. maxcount
	loop
		-- delete every 5th row
		if mod(n,5) = 0 then

			-- delete the row
			delete from idx_fragment where pk = n;

			-- put it back
			insert into idx_fragment(pk,testdata )
			values(n, insert_str);

		end if;
	end loop;
	commit;
end;
/

select
	segment_name,
	decode(extent_id,0,'0',to_char(extent_id)) extent_id,
	bytes
from dba_extents
where owner = USER
and segment_name = 'IDX_FRAGMENT_IDX'
order by tablespace_name, segment_type, segment_name
/

select count(*) IDX_FRAGMENT_ROW_COUNT from idx_fragment;

prompt rebuilding the index 

alter index idx_fragment_idx rebuild;

select
	segment_name,
	decode(extent_id,0,'0',to_char(extent_id)) extent_id,
	bytes
from dba_extents
where owner = USER
and segment_name = 'IDX_FRAGMENT_IDX'
order by tablespace_name, segment_type, segment_name
/

spool off



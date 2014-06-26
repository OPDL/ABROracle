
create table pdba_sequences
as
select *
from dba_sequences
where 1=2;

alter table pdba_sequences add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_tablespaces
as 
select 
	contents ,initial_extent ,logging ,max_extents
	,min_extents ,min_extlen ,next_extent ,pct_increase
	,status ,tablespace_name
from dba_tablespaces
where 1=2;

alter table pdba_tablespaces add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_users
as
select 
	account_status ,created ,default_tablespace ,expiry_date
	,external_name ,lock_date ,password ,profile
	,temporary_tablespace ,username ,user_id
from dba_users
where 1=2;

alter table pdba_users add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_tables
as
select 
	temporary ,last_analyzed ,blocks ,backed_up ,chain_cnt
	,partitioned ,ini_trans,freelists ,iot_name ,table_lock
	,empty_blocks ,max_trans ,instances ,sample_size ,iot_type
	,avg_space_freelist_blocks ,pct_free ,owner ,cache
	,tablespace_name ,avg_row_len ,next_extent ,cluster_name
	,avg_space ,buffer_pool ,min_extents ,num_freelist_blocks
	,freelist_groups ,nested ,max_extents ,pct_increase
	,pct_used ,num_rows ,logging ,initial_extent
	,table_name ,degree
from dba_tables
where 1=2;

alter table pdba_tables add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_tab_columns
as
select 
	owner, table_name, column_name, data_type, data_type_mod, data_type_owner,
	data_length, data_precision, data_scale, nullable, column_id, default_length,
	num_distinct, low_value, high_value, density, num_nulls, num_buckets,
	last_analyzed, sample_size, character_set_name, char_col_decl_length
from dba_tab_columns
where 1=2;

alter table pdba_tab_columns add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_indexes
as
select
	avg_data_blocks_per_key ,avg_leaf_blocks_per_key ,blevel ,buffer_pool
	,clustering_factor ,degree ,distinct_keys ,freelists ,freelist_groups
	,generated ,include_column ,index_name ,index_type ,initial_extent
	,ini_trans ,instances ,last_analyzed ,leaf_blocks ,logging ,max_extents
	,max_trans ,min_extents ,next_extent ,num_rows ,owner ,partitioned
	,pct_free ,pct_increase ,pct_threshold ,sample_size ,status ,tablespace_name
	,table_name ,table_owner ,table_type ,temporary ,uniqueness
from dba_indexes
where 1=2;

alter table pdba_indexes add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_ind_columns
as
select 
	column_length ,column_name ,column_position ,index_name
	,index_owner ,table_name ,table_owner
from dba_ind_columns
where 1=2;

alter table pdba_ind_columns modify( column_name varchar2(30));

alter table pdba_ind_columns add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_profiles
as
select *
from dba_profiles
where 1=2;

alter table pdba_profiles add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_roles
as
select *
from dba_roles
where 1=2;

alter table pdba_roles add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_role_privs
as
select *
from dba_role_privs
where 1=2;

alter table pdba_role_privs add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_tab_privs
as
select *
from dba_tab_privs
where 1=2;

alter table pdba_tab_privs add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_sys_privs
as
select *
from dba_sys_privs
where 1=2;

alter table pdba_sys_privs add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);

create table pdba_parameters
as
select *
from v$parameter
where 1=2;

alter table pdba_parameters add (
	pk number(12) not null,
	snap_date_pk number(12) not null
);


create table pdba_snap_dates (
	pk number(12) not null,
	global_name varchar(40) not null,
	snap_date date not null
);



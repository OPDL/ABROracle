
-- drop sequence
drop sequence pdba_sxp_seq;


-- drop tables
drop table pdba_sxp_exp;
drop table pdba_sxp_sql;
drop table pdba_sxp_dates;

-- create sequence
create sequence pdba_sxp_seq start with 1000000;

-- create tables

	-- snap dates
create table pdba_sxp_dates (
	pk number(12) not null
	, snap_date date not null
	, global_name varchar2(40) not null
)
tablespace pdba_data
/

	-- table for sql text
create table pdba_sxp_sql (
	pk number(12) not null
	, snap_date_pk number(12) not null
	, chksum varchar2(32) not null
	, username varchar2(30) not null
	, sqltext clob
)
lob (sqltext) store as (storage (initial 8k next 8k ))
tablespace pdba_data
/


	-- table for explain plan text
create table pdba_sxp_exp (
	pk number(12) not null
	, pdba_sxp_sql_pk number(12) not null
	, chksum varchar2(32) 
	, explain_error varchar2(100)
	, exptext clob
)
lob (exptext) store as (storage (initial 8k next 8k ))
tablespace pdba_data
/


-- indexes

	-- snap dates
create unique index pdba_sxp_dates_pk_idx
on pdba_sxp_dates(pk)
tablespace pdba_idx
/

	-- sql text
create unique index pdba_sxp_sql_pk_idx
on pdba_sxp_sql(pk)
tablespace pdba_idx
/

create unique index pdba_sxp_sql_uk_idx
on pdba_sxp_sql(username, chksum, snap_date_pk)
tablespace pdba_idx
/

	-- explain plans
create unique index pdba_sxp_exp_pk_idx
on pdba_sxp_exp(pk)
tablespace pdba_idx
/

create unique index pdba_sxp_exp_uk_idx
on pdba_sxp_exp(chksum, pdba_sxp_sql_pk)
tablespace pdba_idx
/


-- create pk

alter table pdba_sxp_dates add constraint pdba_sxp_dates_pk
primary key(pk);

alter table pdba_sxp_sql add constraint pdba_sxp_sql_pk
primary key(pk);

alter table pdba_sxp_exp add constraint pdba_sxp_exp_pk
primary key(pk);

-- create fk

alter table pdba_sxp_sql add constraint pdba_sxp_sql_snap_date_fk
foreign key( snap_date_pk )
references pdba_sxp_dates(pk);

alter table pdba_sxp_exp add constraint pdba_exp_sql_snap_date_fk
foreign key(  pdba_sxp_sql_pk )
references pdba_sxp_sql(pk);


-- triggers

create or replace trigger pdba_sxp_dates_pk_trg
before insert on pdba_sxp_dates
for each row
declare
	vPK pls_integer;
begin
	select pdba_sxp_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

create or replace trigger pdba_sxp_sql_pk_trg
before insert on pdba_sxp_sql
for each row
declare
	vPK pls_integer;
begin
	select pdba_sxp_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

create or replace trigger pdba_sxp_exp_pk_trg
before insert on pdba_sxp_exp
for each row
declare
	vPK pls_integer;
begin
	select pdba_sxp_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/



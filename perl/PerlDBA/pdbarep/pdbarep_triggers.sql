create or replace trigger PDBA_SEQUENCES_pk_trg
before insert on PDBA_SEQUENCES
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_SEQUENCES_pk_trg

create or replace trigger PDBA_INDEXES_pk_trg
before insert on PDBA_INDEXES
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_INDEXES_pk_trg

create or replace trigger PDBA_IND_COLUMNS_pk_trg
before insert on PDBA_IND_COLUMNS
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_IND_COLUMNS_pk_trg

create or replace trigger PDBA_PARAMETERS_pk_trg
before insert on PDBA_PARAMETERS
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_PARAMETERS_pk_trg

create or replace trigger PDBA_PROFILES_pk_trg
before insert on PDBA_PROFILES
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_PROFILES_pk_trg

create or replace trigger PDBA_ROLES_pk_trg
before insert on PDBA_ROLES
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_ROLES_pk_trg

create or replace trigger PDBA_ROLE_PRIVS_pk_trg
before insert on PDBA_ROLE_PRIVS
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_ROLE_PRIVS_pk_trg

create or replace trigger PDBA_SNAP_DATES_pk_trg
before insert on PDBA_SNAP_DATES
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_SNAP_DATES_pk_trg

create or replace trigger PDBA_SYS_PRIVS_pk_trg
before insert on PDBA_SYS_PRIVS
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_SYS_PRIVS_pk_trg

create or replace trigger PDBA_TABLES_pk_trg
before insert on PDBA_TABLES
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_TABLES_pk_trg

create or replace trigger PDBA_TABLESPACES_pk_trg
before insert on PDBA_TABLESPACES
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_TABLESPACES_pk_trg

create or replace trigger PDBA_TAB_COLUMNS_pk_trg
before insert on PDBA_TAB_COLUMNS
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_TAB_COLUMNS_pk_trg

create or replace trigger PDBA_TAB_PRIVS_pk_trg
before insert on PDBA_TAB_PRIVS
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_TAB_PRIVS_pk_trg

create or replace trigger PDBA_USERS_pk_trg
before insert on PDBA_USERS
for each row
declare
	vPK pls_integer;
begin
	select pdbarep_seq.nextval into vPK
	from dual;
	:new.pk := vPK;
end;
/

show errors trigger PDBA_USERS_pk_trg


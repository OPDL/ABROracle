alter table PDBA_SEQUENCES add constraint PDBA_SEQUENCES_pk
	primary key(pk);

alter table PDBA_INDEXES add constraint PDBA_INDEXES_pk
	primary key(pk);

alter table PDBA_IND_COLUMNS add constraint PDBA_IND_COLUMNS_pk
	primary key(pk);

alter table PDBA_PARAMETERS add constraint PDBA_PARAMETERS_pk
	primary key(pk);

alter table PDBA_PROFILES add constraint PDBA_PROFILES_pk
	primary key(pk);

alter table PDBA_ROLES add constraint PDBA_ROLES_pk
	primary key(pk);

alter table PDBA_ROLE_PRIVS add constraint PDBA_ROLE_PRIVS_pk
	primary key(pk);

alter table PDBA_SNAP_DATES add constraint PDBA_SNAP_DATES_pk
	primary key(pk);

alter table PDBA_SYS_PRIVS add constraint PDBA_SYS_PRIVS_pk
	primary key(pk);

alter table PDBA_TABLES add constraint PDBA_TABLES_pk
	primary key(pk);

alter table PDBA_TABLESPACES add constraint PDBA_TABLESPACES_pk
	primary key(pk);

alter table PDBA_TAB_COLUMNS add constraint PDBA_TAB_COLUMNS_pk
	primary key(pk);

alter table PDBA_TAB_PRIVS add constraint PDBA_TAB_PRIVS_pk
	primary key(pk);

alter table PDBA_USERS add constraint PDBA_USERS_pk
	primary key(pk);

alter table PDBA_SEQUENCES add constraint PDBA_SEQUENCES_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_INDEXES add constraint PDBA_INDEXES_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_IND_COLUMNS add constraint PDBA_IND_COLUMNS_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_PARAMETERS add constraint PDBA_PARAMETERS_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_PROFILES add constraint PDBA_PROFILES_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_ROLES add constraint PDBA_ROLES_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_ROLE_PRIVS add constraint PDBA_ROLE_PRIVS_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_SYS_PRIVS add constraint PDBA_SYS_PRIVS_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_TABLES add constraint PDBA_TABLES_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_TABLESPACES add constraint PDBA_TABLESPACES_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_TAB_COLUMNS add constraint PDBA_TAB_COLUMNS_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_TAB_PRIVS add constraint PDBA_TAB_PRIVS_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);

alter table PDBA_USERS add constraint PDBA_USERS_snap_fk
	foreign key(snap_date_pk)
	references pdba_snap_dates(pk);


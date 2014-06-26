create unique index PDBA_SEQUENCES_pk_idx
on PDBA_SEQUENCES(pk)
tablespace pdba_idx;

create unique index PDBA_INDEXES_pk_idx
on PDBA_INDEXES(pk)
tablespace pdba_idx;

create unique index PDBA_IND_COLUMNS_pk_idx
on PDBA_IND_COLUMNS(pk)
tablespace pdba_idx;

create unique index PDBA_PARAMETERS_pk_idx
on PDBA_PARAMETERS(pk)
tablespace pdba_idx;

create unique index PDBA_PROFILES_pk_idx
on PDBA_PROFILES(pk)
tablespace pdba_idx;

create unique index PDBA_ROLES_pk_idx
on PDBA_ROLES(pk)
tablespace pdba_idx;

create unique index PDBA_ROLE_PRIVS_pk_idx
on PDBA_ROLE_PRIVS(pk)
tablespace pdba_idx;

create unique index PDBA_SNAP_DATES_pk_idx
on PDBA_SNAP_DATES(pk)
tablespace pdba_idx;

create unique index PDBA_SYS_PRIVS_pk_idx
on PDBA_SYS_PRIVS(pk)
tablespace pdba_idx;

create unique index PDBA_TABLES_pk_idx
on PDBA_TABLES(pk)
tablespace pdba_idx;

create unique index PDBA_TABLESPACES_pk_idx
on PDBA_TABLESPACES(pk)
tablespace pdba_idx;

create unique index PDBA_TAB_COLUMNS_pk_idx
on PDBA_TAB_COLUMNS(pk)
tablespace pdba_idx;

create unique index PDBA_TAB_PRIVS_pk_idx
on PDBA_TAB_PRIVS(pk)
tablespace pdba_idx;

create unique index PDBA_USERS_pk_idx
on PDBA_USERS(pk)
tablespace pdba_idx;

create index PDBA_SEQUENCES_snap_fk_idx
on PDBA_SEQUENCES( snap_date_pk )
tablespace pdba_idx;

create index PDBA_INDEXES_snap_fk_idx
on PDBA_INDEXES( snap_date_pk )
tablespace pdba_idx;

create index PDBA_IND_COLUMNS_snap_fk_idx
on PDBA_IND_COLUMNS( snap_date_pk )
tablespace pdba_idx;

create index PDBA_PARAMETERS_snap_fk_idx
on PDBA_PARAMETERS( snap_date_pk )
tablespace pdba_idx;

create index PDBA_PROFILES_snap_fk_idx
on PDBA_PROFILES( snap_date_pk )
tablespace pdba_idx;

create index PDBA_ROLES_snap_fk_idx
on PDBA_ROLES( snap_date_pk )
tablespace pdba_idx;

create index PDBA_ROLE_PRIVS_snap_fk_idx
on PDBA_ROLE_PRIVS( snap_date_pk )
tablespace pdba_idx;

create index PDBA_SYS_PRIVS_snap_fk_idx
on PDBA_SYS_PRIVS( snap_date_pk )
tablespace pdba_idx;

create index PDBA_TABLES_snap_fk_idx
on PDBA_TABLES( snap_date_pk )
tablespace pdba_idx;

create index PDBA_TABLESPACES_snap_fk_idx
on PDBA_TABLESPACES( snap_date_pk )
tablespace pdba_idx;

create index PDBA_TAB_COLUMNS_snap_fk_idx
on PDBA_TAB_COLUMNS( snap_date_pk )
tablespace pdba_idx;

create index PDBA_TAB_PRIVS_snap_fk_idx
on PDBA_TAB_PRIVS( snap_date_pk )
tablespace pdba_idx;

create index PDBA_USERS_snap_fk_idx
on PDBA_USERS( snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_SEQUENCES_uk_idx
on PDBA_SEQUENCES( sequence_owner, sequence_name, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_INDEXES_uk_idx
on PDBA_INDEXES( owner, index_name, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_IND_COLUMNS_uk_idx
on PDBA_IND_COLUMNS( index_owner, index_name, column_name, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_PARAMETERS_uk_idx
on PDBA_PARAMETERS( name, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_PROFILES_uk_idx
on PDBA_PROFILES( profile, resource_name, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_ROLES_uk_idx
on PDBA_ROLES( role, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_ROLE_PRIVS_uk_idx
on PDBA_ROLE_PRIVS( grantee, granted_role, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_SNAP_DATES_uk_idx
on PDBA_SNAP_DATES( snap_date )
tablespace pdba_idx;

create unique index PDBA_SYS_PRIVS_uk_idx
on PDBA_SYS_PRIVS( grantee, privilege, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_TABLES_uk_idx
on PDBA_TABLES( owner, table_name, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_TABLESPACES_uk_idx
on PDBA_TABLESPACES( tablespace_name, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_TAB_COLUMNS_uk_idx
on PDBA_TAB_COLUMNS( owner, table_name, column_name, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_TAB_PRIVS_uk_idx
on PDBA_TAB_PRIVS( grantee, table_name, privilege, grantor, snap_date_pk )
tablespace pdba_idx;

create unique index PDBA_USERS_uk_idx
on PDBA_USERS( username, snap_date_pk )
tablespace pdba_idx;


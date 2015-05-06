/* Run as sys */
UNDEF USER

grant select on dba_synonyms to &&USER;
grant select on v_$parameter to &&USER;
grant select on sys.dba_segments to &&USER;
grant select on sys.dba_tables to &&USER;
grant select on sys.dba_indexes to &&USER;
grant select on sys.dba_synonyms to &&USER;

UNDEF USER

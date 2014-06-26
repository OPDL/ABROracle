--@pdbarep_drop.sql

spool pdbarep_create.log

@pdbarep_tables.sql
@pdbarep_indexes.sql
@pdbarep_constraints.sql
@pdbarep_sequences.sql
@pdbarep_triggers.sql

spool off


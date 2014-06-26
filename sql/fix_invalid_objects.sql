/* 
@/u01/app/oracle/product/11.2.0.3/dbhome_1/rdbms/admin/utlrp.sql
can sometimes throw errors on DBs with Large Number of Procs, smaller-ish
SGA, and parallelism  set high.  utlrp.sql calls utlprp.sql 0, max power,
utlprp.sql 8 will run slower, but not throw errors.

*/

@?/rdbms/admin/utlprp.sql 8

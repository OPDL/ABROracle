set serveroutput on size 1000000
DECLARE
  retval PLS_INTEGER;
BEGIN
-- dbms_output.enable(1000000);
		DBMS_OUTPUT.PUT_LINE(' Gather Stats  Start' );
    FOR rec IN (SELECT * 
                FROM all_tables
                WHERE owner NOT IN ('SYS','SYSTEM','XDB','CTXSYS','EXFSYS','ODMRSYS','OUTLN','WMSYS'))
    LOOP
	BEGIN
		DBMS_OUTPUT.PUT_LINE(' Gather Stats  : ' || rec.owner || '.' || rec.table_name );
		dbms_stats.gather_table_stats(rec.owner, rec.table_name);
	EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE(' Error code    : ' || TO_CHAR(SQLCODE));
		DBMS_OUTPUT.PUT_LINE(' Error Message : ' || SQLERRM);
	END;
    END LOOP;
		DBMS_OUTPUT.PUT_LINE(' Gather Stats  End' );
END;
/

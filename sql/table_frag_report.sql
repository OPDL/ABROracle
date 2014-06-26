SET SERVEROUTPUT ON SIZE 10

DECLARE 
CURSOR c_tables IS SELECT owner, table_name FROM all_tables where owner not in (select user_name from sys.DEFAULT_PWD$) 
and owner not in ('ODMRSYS');
l_rec c_tables%ROWTYPE;
l_total INTEGER := 0;
l_count INTEGER;
is_stale VARCHAR2(3 char);
sqlstr VARCHAR2(4000 char);
BEGIN
	OPEN c_tables;
	FETCH c_tables INTO l_rec;
	WHILE c_tables%FOUND LOOP
	DBMS_OUTPUT.PUT_LINE('Processing: ' || l_rec.owner || ':' || l_rec.table_name);
	DBMS_APPLICATION_INFO.SET_MODULE(MODULE_NAME=>'TABLEFRAG',ACTION_NAME=>'BEGIN');

	DBMS_APPLICATION_INFO.SET_CLIENT_INFO(CLIENT_INFO=>'Client Info '||sysdate);

BEGIN
	DBMS_APPLICATION_INFO.SET_ACTION(ACTION_NAME=>'Gather Stats');

	EXECUTE IMMEDIATE 'select stale_stats from dba_tab_statistics where owner = '''||l_rec.owner||''' and table_name = '''||l_rec.table_name || '''' into is_stale;



	DBMS_OUTPUT.PUT_LINE('Processing: ' || l_rec.owner || ':' || l_rec.table_name || ' Stale:' || is_stale);
--	dbms_stats.gather_table_stats(l_rec.owner,l_rec.table_name);
EXCEPTION 
	WHEN OTHERS 
	THEN DBMS_OUTPUT.PUT_LINE('Failed   Gather Stats: ' || l_rec.owner || ':' || l_rec.table_name || ':' || SQLERRM || ':' || SQLCODE );
END;
BEGIN
	DBMS_APPLICATION_INFO.SET_ACTION(ACTION_NAME=>'Check frag');
	EXECUTE IMMEDIATE 'SELECT count(1) FROM "'||l_rec.owner||'"."'||l_rec.table_name || '"' INTO l_count;
	l_total := l_total + l_count;
	DBMS_OUTPUT.PUT_LINE('Schema: ' || l_rec.owner || ' - ' || l_count);
sqlstr := 'select a.*,case when a."AllocSize Kb" = 0 then -1 else ROUND(((a."AllocSize Kb"- a."DataSize kb")/(a."AllocSize Kb")),2) end  as "PCT FRAG" from ' ||
'( Select owner, table_name, blocks "EverUsed" , round((blocks*(select value/1000 from v$parameter where upper(name) = ''DB_BLOCK_SIZE'')),2) "AllocSize Kb" ' ||
', empty_blocks "NeverUsed" , num_rows "Rows" , pct_free , round((num_rows*avg_row_len/1024),2) "DataSize kb" ' ||
'from all_tables where owner = ''' ||l_rec.owner ||''' and table_name=''' ||l_rec.table_name ||''' ) a';
-- dbms_output.put_line(sqlstr);
execute immediate sqlstr;
EXCEPTION
	WHEN OTHERS 
	THEN DBMS_OUTPUT.PUT_LINE('Failed   Count: ' || l_rec.owner || ':' || l_rec.table_name  || ':' || SQLERRM);
END;
		FETCH c_tables INTO l_rec;
	END LOOP;
	CLOSE c_tables;
	DBMS_OUTPUT.PUT_LINE('Grand total: ' || l_total);
select * from all_tables;
END;
/

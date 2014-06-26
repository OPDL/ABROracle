DECLARE
        v_CursorID  NUMBER;
        v_table VARCHAR2(50):='test';
        v_SelectRecords  VARCHAR2(500);
        v_NUMRows  INTEGER;
        v_MyNum INTEGER;
        v_Myname VARCHAR2(50);
        v_Rank INTEGER;



    BEGIN
         v_CursorID := DBMS_SQL.OPEN_CURSOR;
        v_SelectRecords := 'SELECT * from ' || v_table ;
        DBMS_SQL.PARSE(v_CursorID,v_SelectRecords,DBMS_SQL.V7);
        DBMS_SQL.DEFINE_COLUMN(v_CursorID,1,v_MyNum);
        DBMS_SQL.DEFINE_COLUMN(v_CursorID,2,v_Myname,50);
        DBMS_SQL.DEFINE_COLUMN(v_CursorID,3,v_Rank);

        v_NumRows := DBMS_SQL.EXECUTE(v_CursorID);
   LOOP
        IF DBMS_SQL.FETCH_ROWS(v_CursorID) = 0 THEN
             EXIT;
        END IF;

        DBMS_SQL.COLUMN_VALUE(v_CursorId,1,v_MyNum);
        DBMS_SQL.COLUMN_VALUE(v_CursorId,2,v_Myname);
        DBMS_SQL.COLUMN_VALUE(v_CursorId,3,v_Rank);



        DBMS_OUTPUT.PUT_LINE(v_MyNum || ' ' || v_Myname || ' ' || v_Rank  );

   END LOOP;

   EXCEPTION
        WHEN OTHERS THEN
                  RAISE;
        DBMS_SQL.CLOSE_CURSOR(v_CursorID);
        end;

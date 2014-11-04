-- identify invalid numbers in a column of data
DECLARE
  --declare the cursor
  CURSOR cur_example is
    select distinct gmobj from PRODDTA.F0901;
    
  /*create a record to store the data of the table,
  note the datatype of the record as row type of cur_example*/
  rec_example cur_example%ROWTYPE;
  n number;
BEGIN
  --open the cursor to iterate it
  OPEN cur_example;
  --loop until there is a condition to stop
  LOOP
    --fetch a row data from the cursor and store it in rec_example
    FETCH cur_example INTO rec_example;
    --if there is no more data in the cursor then exit
    EXIT WHEN cur_example%NOTFOUND;
    /*output the values of the cursor to the console
    note the use of . to access the fields of the record*/
    --DBMS_OUTPUT.put_line('Number value is: ' || rec_example.gmobj);
    BEGIN
    n := rec_example.gmobj;
    EXCEPTION
         WHEN OTHERS
          THEN
          DBMS_OUTPUT.put_line('ERROR value: [' || rec_example.gmobj || ']');
    END;
  END LOOP;
  --close the cursor
  CLOSE cur_example;
  
END;
/

select gmobj from (select distinct gmobj from PRODDTA.F0901) WHERE trim(translate(gmobj, '0123456789', ' ')) IS NOT NULL;


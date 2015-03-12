CREATE OR REPLACE PACKAGE test AS

    TYPE measure_record IS RECORD(
       l4_id VARCHAR2(50), 
       l6_id VARCHAR2(50), 
       l8_id VARCHAR2(50), 
       year NUMBER, 
       period NUMBER,
       VALUE NUMBER);

    TYPE measure_table IS TABLE OF measure_record;

    FUNCTION get_ups(foo NUMBER)
        RETURN measure_table
        PIPELINED;
END;
/
CREATE OR REPLACE PACKAGE BODY test AS

    FUNCTION get_ups(foo number)
        RETURN measure_table
        PIPELINED IS

        rec            measure_record;

    BEGIN
        SELECT 'foo', 'bar', 'baz', 2010, 5, foo
          INTO rec
          FROM DUAL;

        -- you would usually have a cursor and a loop here   
        PIPE ROW (rec);

        RETURN;
    END get_ups;
END;
/

-- test
select * from table(test.get_ups(4444));
/


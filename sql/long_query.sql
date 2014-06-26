CREATE OR REPLACE FUNCTION query_wait
(
   i_wait_secs IN PLS_INTEGER
)
   RETURN NUMBER
IS
BEGIN
   DBMS_LOCK.SLEEP(i_wait_secs);
   RETURN i_wait_secs;
END;
/
SELECT query_wait(10)
 FROM dual
 /

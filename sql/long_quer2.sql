CREATE OR REPLACE FUNCTION query_wait
(
   i_wait_secs IN PLS_INTEGER
)
RETURN NUMBER
IS
v_now DATE;
BEGIN
select sysdate into v_now from dual;

LOOP
  EXIT WHEN ((v_now + (i_wait_secs * (1/86400))) <= SYSDATE);
END LOOP;
   RETURN i_wait_secs;
END;
/

select query_wait(10) from dual;
/


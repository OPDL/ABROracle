CREATE TABLE "CUSTOMER"
  (
    "ID"       NUMBER,
    "ACCT_NUM" NUMBER,
    "NAME"     VARCHAR2(100 CHAR),
    "DT"       DATE
  )
  NOCOMPRESS LOGGING;
COMMIT;
TRUNCATE TABLE customer;
SELECT COUNT(*) FROM customer;
SET timing ON;
INSERT INTO customer
  ( "ID" ,"ACCT_NUM","NAME","DT"
  )
SELECT LEVEL "ID",
  TRUNC (DBMS_RANDOM.VALUE (10000, 100000), 2) "ACCT_NUM",
  DBMS_RANDOM.string ('U', 20) "NAME",
  TO_DATE ('1990-01-01', 'yyyy-mm-dd')+ TRUNC(DBMS_RANDOM.VALUE (1, 6000), 0) DT
FROM DUAL
  CONNECT BY LEVEL <= 10000;
COMMIT;
SET timing OFF;
ALTER TABLE customer nologging;
COMMIT;
SET timing ON;
INSERT /*+ APPEND */
INTO customer
  ( "ID" ,"ACCT_NUM","NAME","DT"
  )
SELECT LEVEL "ID",
  TRUNC (DBMS_RANDOM.VALUE (10000, 100000), 2) "ACCT_NUM",
  DBMS_RANDOM.string ('U', 20) "NAME",
  TO_DATE ('1990-01-01', 'yyyy-mm-dd')+ TRUNC(DBMS_RANDOM.VALUE (1, 6000), 0) DT
FROM DUAL
  CONNECT BY LEVEL <= 10000;
ALTER TABLE customer logging;
COMMIT;
SET timing OFF;

truncate table customer;

ALTER TABLE customer logging;
SELECT COUNT(*) FROM customer;
SET AUTOTRACE ON STATISTICS;
set timing on;

DECLARE
  cnt NUMBER;
BEGIN
cnt := 1000;
  FOR i IN 1..cnt
  LOOP
    INSERT INTO customer
      ( "ID" ,"ACCT_NUM","NAME","DT")
      SELECT TRUNC (DBMS_RANDOM.VALUE (1, 100000),0) "ID",
      TRUNC (DBMS_RANDOM.VALUE (10000, 100000), 2) "ACCT_NUM",
      DBMS_RANDOM.string ('U', 20) "NAME",
      TO_DATE ('1990-01-01', 'yyyy-mm-dd')+ TRUNC(DBMS_RANDOM.VALUE (1, 6000), 0) DT
    FROM DUAL;
  END LOOP;
END;
/
commit;
/

ALTER TABLE customer nologging;
SELECT COUNT(*) FROM customer;
set timing on;
SET AUTOTRACE ON STATISTICS;

DECLARE
  cnt NUMBER;
BEGIN
cnt := 1000;
  FOR i IN 1..cnt
  LOOP
-- To allow the APPEND hint to have an impact on redo generation, we must set the table to NOLOGGING
-- Except in the case of a NOARCHIVELOG mode database, the APPEND hint will only reduce redo generation 
-- if the table or tablespace is set to NOLOGGING.
    INSERT /*+ APPEND */ INTO customer
      ( "ID" ,"ACCT_NUM","NAME","DT")
      SELECT TRUNC (DBMS_RANDOM.VALUE (1, 100000),0) "ID",
      TRUNC (DBMS_RANDOM.VALUE (10000, 100000), 2) "ACCT_NUM",
      DBMS_RANDOM.string ('U', 20) "NAME",
      TO_DATE ('1990-01-01', 'yyyy-mm-dd')+ TRUNC(DBMS_RANDOM.VALUE (1, 6000), 0) DT
    FROM DUAL;
  END LOOP;
END;
/
commit;
/
set timing off;
ALTER TABLE customer logging;
commit;
SELECT COUNT(*) FROM customer;
/


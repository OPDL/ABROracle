SELECT *
  FROM YOUR_TABLE
 WHERE creation_date <= TRUNC(SYSDATE) - 30
SYSDATE returns the date & time; TRUNC resets the date to being as of midnight so you can omit it if you want the creation_date that is 30 days previous including the current time.

Depending on your needs, you could also look at using ADD_MONTHS:

SELECT *
  FROM YOUR_TABLE
 WHERE creation_date <= ADD_MONTHS(TRUNC(SYSDATE), -1)
-- trunc will force datetime to midight or basically work with days and not hours
select to_char(TRUNC(SYSDATE) - interval '1' month,'YYYY-MM-DD HH24:MI:SS') DT from dual;
select to_char(SYSDATE - interval '1' month,'YYYY-MM-DD HH24:MI:SS') DT from dual;


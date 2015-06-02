//create history table
create table SVM900.F986110_EPC_HISTORY
tablespace SVM900T
as
select * from SVM900.F986110
order by JCEXEHOST, JCJOBNBR;
commit;
ALTER TABLE SVM900.F986110_EPC_HISTORY ADD CONSTRAINT "F986110_EPC_HISTORY_PK" PRIMARY KEY ("JCEXEHOST", "JCJOBNBR");
commit;

// insert missing records
insert into SVM900.F986110_EPC_HISTORY
SELECT * FROM
( 
WITH DS AS
  (SELECT 
     s.*
  FROM SVM900.F986110 s
  LEFT OUTER JOIN SVM900.F986110_EPC_HISTORY t
  ON (s.JCEXEHOST    = t.JCEXEHOST)
  AND (s.JCJOBNBR    = t.JCJOBNBR)
  WHERE t.JCSBMDATE IS NULL
  )
SELECT * from DS
);


// confirm
select count(*) from SVM900.F986110;
select count(*) from SVM900.F986110_EPC_HISTORY;

// delete records older than 2 years
select JCSBMDATE, TO_DATE(TO_CHAR(to_number(JCSBMDATE)+1900000), 'YYYYDDD') as DT from SVM900.F986110_EPC_HISTORY
WHERE
TO_DATE(TO_CHAR(to_number(JCSBMDATE)+1900000), 'YYYYDDD') < (SYSDATE - interval '24' month)

Delete SVM900.F986110_EPC_HISTORY
WHERE
TO_DATE(TO_CHAR(to_number(JCSBMDATE)+1900000), 'YYYYDDD') < (SYSDATE - interval '24' month)


select
to_date(substr('115141',2,5),'YYDDD'),'MM/DD/YYYY'
from dual ;

select TO_DATE(TO_CHAR(to_number('115141')+1900000), 'YYYYDDD') from dual;
select to_number(to_char(to_date('05/21/2015','MM/DD/YYYY'),'RRRRDDD'))-1900000 from dual;

select TO_DATE(TO_CHAR(to_number('108005')+1900000), 'YYYYDDD') from dual;
select to_number(to_char(to_date('01/05/2008','MM/DD/YYYY'),'RRRRDDD'))-1900000 from dual;


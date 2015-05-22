
select TO_DATE(TO_CHAR(to_number('115141')+1900000), 'YYYYDDD') from dual;
select to_number(to_char(to_date('05/21/2015','MM/DD/YYYY'),'RRRRDDD'))-1900000 from dual;

select TO_DATE(TO_CHAR(to_number('108005')+1900000), 'YYYYDDD') from dual;
select to_number(to_char(to_date('01/05/2008','MM/DD/YYYY'),'RRRRDDD'))-1900000 from dual;


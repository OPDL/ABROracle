select JCUSER,TO_DATE(TO_CHAR(to_number(JCSBMDATE)+1900000), 'YYYYDDD'), JCSBMTIME,JCFNDFUF2,trim(regexp_substr(JCFNDFUF2, '[^_]+', 1, 1)) from SVM900.F986110_EPC_HISTORY


With d as
(
select EXTRACT (YEAR from D) as"YEAR" ,EXTRACT (MONTH from D) as "M" ,RPT from
  (
  select JCUSER,TO_DATE(TO_CHAR(to_number(JCSBMDATE)+1900000), 'YYYYDDD') AS "D", JCSBMTIME,JCFNDFUF2,trim(regexp_substr(JCFNDFUF2, '[^_]+', 1, 1)) as "RPT" from SVM900.F986110_EPC_HISTORY
  )
  )
select "YEAR","M","RPT",count("RPT") from d
group by rollup("YEAR","M","RPT")

select trim(regexp_substr(JCFNDFUF2, '[^_]+', 1, 1)) as "RPT", count(*)  from SVM900.F986110_EPC_HISTORY
group by 
trim(regexp_substr(JCFNDFUF2, '[^_]+', 1, 1))
order by 2 desc;



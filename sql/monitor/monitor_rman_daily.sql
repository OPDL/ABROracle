-- Adam Richards
-- show rman history for last 7 days
DEFINE DAY_RANGE=1
set feedback off
set verify off
set pagesize 9999
set linesize 9999
set colsep '|'
ALTER SESSION SET NLS_DATE_FORMAT ='MM-DD-YYYY HH24:MI:SS';

select * from (
select HOST,DBNAME,&DAY_RANGE as "DAY_RANGE",OPERATION,STATUS,COUNT(*) as CNT from
(
SELECT 
  CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(20)) as "HOST",
  CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME",
  operation || ' ' || object_type as "OPERATION",
  status,
--  row_level,
--  row_type,
  mbytes_processed as MBYTES,
  start_time,
--   end_time,
  cast((24*60*(end_time - start_time)) as number(5)) as time_mins,
--  input_bytes,
--  OUTPUT_BYTES,
	case when operation in ('BACKUP') then 
		case when input_bytes = 0 then 
			null
		else
			cast((100*(input_bytes-output_bytes)/input_bytes) as number(3) )  
		end
	else 
		null 
	end as "COMPRESS_PCT",
  object_type,
  OUTPUT_DEVICE_TYPE,
  optimized
FROM v$rman_status
WHERE start_time > sysdate - &DAY_RANGE
AND row_type    <> 'SESSION'
) a
GROUP BY ROLLUP(HOST,DBNAME,OPERATION,STATUS)
)
where length(trim(status)) > 0
order by cnt desc, operation asc
;


SELECT 
  CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(20)) as "HOST",
  CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME",
  operation,
  status,
--  row_level,
--  row_type,
  mbytes_processed as MBYTES,
  start_time,
--   end_time,
  cast((24*60*(end_time - start_time)) as number(5)) as time_mins,
--  input_bytes,
--  OUTPUT_BYTES,
	case when operation in ('BACKUP') then 
		case when input_bytes = 0 then 
			null
		else
			cast((100*(input_bytes-output_bytes)/input_bytes) as number(3) )  
		end
	else 
		null 
	end as "COMPRESS_PCT",
  object_type,
  OUTPUT_DEVICE_TYPE,
  optimized
FROM v$rman_status
WHERE 
start_time > sysdate - &DAY_RANGE
AND upper(row_type)    <> 'SESSION'
AND upper(status) not in ('COMPLETED')
ORDER BY start_time DESC;


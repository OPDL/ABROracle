-- Adam Richards
-- show rman history for last 7 days
set feedback off
set pagesize 9999
set linesize 9999
set colsep '|'
DEFINE DAY_RANGE=7
ALTER SESSION SET NLS_DATE_FORMAT ='MM-DD-YYYY HH24:MI:SS';
select HOST,DBNAME,OPERATION,STATUS,COUNT(*) as CNT from
(
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
WHERE start_time > sysdate - &DAY_RANGE
AND row_type    <> 'SESSION'
) a
GROUP BY ROLLUP(HOST,DBNAME,OPERATION,STATUS)
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
WHERE start_time > sysdate - &DAY_RANGE
AND row_type    <> 'SESSION'
ORDER BY start_time DESC;


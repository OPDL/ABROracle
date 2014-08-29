/* MOS  1454200.1 */

col AGENT format a21
col TARGET_TYPE format a17
col TARGET format a24

set linesize 120
set pagesize 120

SELECT c.target_name Agent,a.target_type,a.target_name Target,
      to_char(alt.last_load_time,'yyyy-mm-dd hh24:mi:ss') Last_load_time ,
      to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') Current_Time
 FROM sysman.mgmt_targets a, sysman.mgmt_targets_load_times alt,
      sysman.mgmt_current_availability b,
      sysman.mgmt_targets c
WHERE c.target_guid in (select target_guid from sysman.mgmt_targets where
target_type='oracle_emd')
  AND c.emd_url = a.emd_url
  AND a.target_guid = b.target_guid
  AND alt.target_guid = a.target_guid
  AND b.current_status = 1
  AND a.broken_reason = 0
  AND a.target_type NOT IN ('oracle_emd','oracle_beacon','oracle_emrep')
  AND alt.last_load_time < ((mgmt_global.sysdate_tzrgn(a.timezone_region)) -
(120 / (24 * 60))) order by 3,4;


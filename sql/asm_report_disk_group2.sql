
set wrap off
set lines 155 pages 9999
col "Group Name" for a10    Head "Group|Name"
col "Disk Name"  for a10
col "State"      for a10
col "Type"       for a10   Head "Diskgroup|Redundancy"
col "Total GB"   for 999,990 Head "Total|GB"
col "Free GB"    for 999,990 Head "Free|GB"
col "Imbalance"  for 99.9  Head "Percent|Imbalance"
col "Variance"   for 99.9  Head "Percent|Disk Size|Variance"
col "MinFree"    for 99.9  Head "Minimum|Percent|Free"
col "MaxFree"    for 99.9  Head "Maximum|Percent|Free"
col "DiskCnt"    for 9999  Head "Disk|Count"
col "asm_compat" for A10
col "db_compat" for A10
 
prompt
prompt ASM Disk Groups
prompt ===============
 
SELECT g.group_number  "Group"
,      g.name          "Group Name"
,      g.state         "State"
,      g.type          "Type"
,      g.total_mb/1024 "Total GB"
,      g.free_mb/1024  "Free GB"
,      100*(max((d.total_mb-d.free_mb)/d.total_mb)-min((d.total_mb-d.free_mb)/d.total_mb))/max((d.total_mb-d.free_mb)/d.total_mb) "Imbalance"
,      100*(max(d.total_mb)-min(d.total_mb))/max(d.total_mb) "Variance"
,      100*(min(d.free_mb/d.total_mb)) "MinFree"
,      100*(max(d.free_mb/d.total_mb)) "MaxFree"
,      count(*)        "DiskCnt"
,g.compatibility AS asm_compat
,g.database_compatibility AS db_compat
FROM v$asm_disk d, v$asm_diskgroup g
WHERE d.group_number = g.group_number and
d.group_number <> 0 and
d.state = 'NORMAL' and
d.mount_status = 'CACHED'
GROUP BY g.group_number, g.name, g.state, g.type, g.total_mb, g.free_mb,g.compatibility,g.database_compatibility
ORDER BY 1;

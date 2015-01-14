set pagesize 9999
set linesize 9999
SELECT name, type, total_mb, free_mb, required_mirror_free_mb, 
     usable_file_mb FROM V$ASM_DISKGROUP;

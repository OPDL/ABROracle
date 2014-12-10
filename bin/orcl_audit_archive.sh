#!/bin/bash
# Author: Adam Richards
# list archive file contents
# tar -tzvf orcl_aud_archive_grid.xa02db01.20141106.tar.gz | cut -d' ' -f6 -
ARCDIR="/orabacklin/archive/orcl_audit_archive"
DAYS=30

function run
{
BFILE="$(basename $AFILE)"
OFILE="${ARCDIR}/${BFILE}"
if [[ -f  "${OFILE}" ]]; then
        echo "Archive file already exists. ${OFILE} "
        return 1;
fi
/usr/bin/find ${FPATH} -maxdepth 1 -name '*.aud' -type f -mtime +"${DAYS}" -print0 | /bin/tar -czvf "${AFILE}" --index-file "${LSTFILE}" --null -T -  2> /dev/null
OK=$?
if [[ ! $OK = 0 ]]; then
	echo "Audit Archive Find failed. $!"
	return $OK
fi
N=$(cat ${LSTFILE} | wc -l)
printf "Oracle Audit Archive: Path: %s, Number of files: %d \n" "${FPATH}" "${N}"
if [[ ! -f  "${OFILE}" ]]; then
	cp "${AFILE}" "${ARCDIR}"
	OK=$?
	if [[ ! $OK = 0 ]]; then
		echo "Audit Archive Copy failed. ${AFILE} $!"
		if [[ -f  "${AFILE}" ]]; then
			rm "${AFILE}"
		fi
		return $OK
	fi
fi
# remove files
cat "${LSTFILE}" | xargs rm
# cleanup
if [[ -f  "${AFILE}" ]]; then
	rm "${AFILE}"
fi
if [[ -f  "${LSTFILE}" ]]; then
	rm "${LSTFILE}"
fi
return 0
}

printf "Oracle Audit File Archive Process Started. %s \n" "$(date +'%Y-%m-%d %H:%M:%S')"
# run on first set of files
LSTFILE="/tmp/orcl_audit_archive_db.$(hostname -s).$(date +%Y%m%d).lst"
AFILE="/tmp/orcl_audit_archive_db.$(hostname -s).$(date +%Y%m%d).tar.gz"
FPATH='/u01/app/oracle/admin/*/adump'
printf "Oracle Audit Archive Run: %s, Older than %s days, Path: %s\n" "$(date +%Y%m%d)" "${DAYS}" "${FPATH}" 
run
OK=$?
#echo ${OK}
# this is for grid and not needed on oem01
# run on second set of files
# LSTFILE="/tmp/orcl_audit_archive_grid.$(hostname -s).$(date +%Y%m%d).lst"
# AFILE="/tmp/orcl_audit_archive_grid.$(hostname -s).$(date +%Y%m%d).tar.gz"
# FPATH="/u01/app/*/grid/rdbms/audit"
# printf "Oracle Audit Archive Run: %s, Older than %s days, Path: %s\n" "$(date +%Y%m%d)" "${DAYS}" "${FPATH}" 
# run
# OK=$?
#echo ${OK}

exit 0

#!/bin/bash
# Author: Adam Richards
# list archive file contents
# tar -tzvf orcl_aud_archive_grid.xa02db01.20141106.tar.gz | cut -d' ' -f6 -
ARCDIR="/orabacklin/archive/orcl_audit_archive"
DAYS=30
#######################################################
function log
{
	D=$(date +%F|tr -d ' ')
	T=$(date +%H:%M:%S|tr -d ' ')
	H=$(hostname -s)
	printf "%-11s|%-9s|%-15s|%-10s|%s\n" "${D}" "${T}" "${H}" "${1}" "${2}"
}
#######################################################
function run
{
BFILE="$(basename $AFILE)"
OFILE="${ARCDIR}/${BFILE}"
if [[ -f  "${OFILE}" ]]; then
        log "ERROR" "Archive file already exists. ${OFILE} "
        return 1;
fi
/usr/bin/find ${FPATH} -maxdepth 1 -name '*.aud' -type f -mtime +"${DAYS}" -print0 | /bin/tar -czvf "${AFILE}" --index-file "${LSTFILE}" --null -T -  2> /dev/null
OK=$?
if [[ ! $OK = 0 ]]; then
	log "WARN" "Audit Archive Find failed. Path: ${FPATH} Message: $!"
	return $OK
fi
N=$(cat ${LSTFILE} | wc -l)
MSG=$(printf "Oracle Audit Archive: Path: %s, Number of files: %d " "${FPATH}" "${N}")
log "INFO" "${MSG}"
if [[ ! -f  "${OFILE}" ]]; then
	cp "${AFILE}" "${ARCDIR}"
	OK=$?
	if [[ ! $OK = 0 ]]; then
		log "ERROR" "Audit Archive Copy failed. ${AFILE} $!"
		if [[ -f  "${AFILE}" ]]; then
			rm "${AFILE}"
		fi
		return $OK
	fi
fi
# remove files
if [[ ! -z $LISTFILE ]]; then
cat "${LSTFILE}" | xargs rm
fi
# cleanup
if [[ -f  "${AFILE}" ]]; then
	rm "${AFILE}"
fi
if [[ -f  "${LSTFILE}" ]]; then
	rm "${LSTFILE}"
fi
return 0
}
#######################################################
printf "Oracle Audit File Archive Process Started. %s \n" "$(date +'%Y-%m-%d %H:%M:%S')"
# run on first set of files
LSTFILE="/tmp/orcl_audit_archive_db.$(hostname -s).$(date +%Y%m%d).lst"
AFILE="/tmp/orcl_audit_archive_db.$(hostname -s).$(date +%Y%m%d).tar.gz"
FPATH='/u01/app/oracle/admin/*/adump'
MSG=$(printf "Oracle Audit Archive Run: Older than %s days, Path: %s" "${DAYS}" "${FPATH}" )
log "INFO" "${MSG}"
run
OK=$?
#######################################################
#echo ${OK}
# run on second set of files
LSTFILE="/tmp/orcl_audit_archive_grid.$(hostname -s).$(date +%Y%m%d).lst"
AFILE="/tmp/orcl_audit_archive_grid.$(hostname -s).$(date +%Y%m%d).tar.gz"
FPATH="/u01/app/*/grid/rdbms/audit"
MSG=$(printf "Oracle Audit Archive Run: Older than %s days, Path: %s" "${DAYS}" "${FPATH}" )
log "INFO" "${MSG}"
run
OK=$?
#echo ${OK}
#######################################################
exit 0

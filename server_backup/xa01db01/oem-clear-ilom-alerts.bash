#!/bin/bash
#From Peter to deal with bugy assert/de-assert ILOM/OEM issues

CFD=" /home/oracle/lcoal/bin/"
CF="${CFD}oem-clear-ilom-alerts.cf"

alerts=0
myhname=`hostname -s`

# Read lines in config file
while read CFLINE ; do
	# Only work with lines specifiied for this host
	if [[ ${CFLINE} =~ ^${myhname}, ]] ; then
		#printf "${CFLINE}\n"
		# Get the selstate filename from the entry
		file=$(echo $CFLINE |cut -d, -f2-)

		# Make sure the file exists
		if [ ! -f "${file}" ] ; then
			echo "Can't find file [${file}] from entry [${CFLINE}]"
		fi

		# Create temporary file with *ONLY* 'RECORD' entries (omitting alerts)
		#  - For small files, this seems easier to implement than checking to see if 
		#    a file needs to be created. The checks I can think of would need to 
		#    process the file to find matches.
		TMPFILE=$(mktemp) && {
			while read LINE ; do
				if [[ ${LINE} =~ ^RECORD|[0-9]+$ ]] ; then
					#printf "[${TMPFILE}] ${LINE}\n"
					printf "${LINE}\n" >> ${TMPFILE}
				else
					((alerts = alerts + 1))
				fi
			done < ${file}
		}
		
		# Only replace the existing file with the tmp file IF an alert was found.
		if [ "${alerts}" -gt 0 ] ; then	
			#echo "Create backup of the original file."
			cp -p ${file} "${file}.prev.`date +%F_%H%M%S`"
		
			#echo "Replace existing file with the new file."
			cp ${TMPFILE} "${file}"

			# Reset the alert counter for processing the next sel state file
			alerts=0
		fi
		#
		##
		### Done with this sel state file, so continue with the next line from the config file
	fi
done < ${CF}

# mktemp cleans up automatically
#rm ${TMPFILE}


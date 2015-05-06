#!/bin/bash
########################################################
NCPU=$(cat /proc/cpuinfo  | grep "^processor" |wc -l)
THREADMAX=$(echo $( expr 0.20*${NCPU} |bc ) | perl -nl -MPOSIX -e 'print ceil($_);')
echo "Using ${THREADMAX} processors out of ${NCPU} available"
echo "Compressing DMP files in parallel ... "
COUNT=0
# dummy first pid
PLIST=""
TOT=23

# LOOP THROUGH FILES
while (true) ; do
COUNT=$(( $COUNT+1 ))
TOT=$(( $TOT-1 ))


# submit a job
printf "starting new process. $COUNT $TOT\n"
R=$(perl -e '$x=10 + int(rand(30 - 10));print $x;')
sleep $R &
#sleep $(( $COUNT * 10 )) &
#find /u01 > /dev/null 2>&1 &
PID=$!
PLIST="${PLIST} $PID"

# limit running processes to max process count
if [[ $(( $COUNT%$THREADMAX )) -eq 0 ]] ; then
	# loop and wait for thread to finish
	while (true); do
	printf "%s\n" "${PLIST}"
        # LOOP THROUGH PID LIST
	for PID in ${PLIST}; do
        ISR=$(ps -p $PID --no-headers | wc -l)
		if [[ $ISR = 0 ]]; then
			PLIST=$(echo "${PLIST}" | sed "s/ $PID//")
			COUNT=$(( $COUNT-1 ))
		fi
	printf "%s %s %s\n" "${PID}" "${ISR}" "${COUNT}"
	done
if [[ $COUNT -lt $THREADMAX ]] ; then
break
fi
        printf "Waiting for threads to finish...\n"
        sleep 5
	done
fi
if [[ $TOT = 0 ]]; then
break
fi
done

# wait for remaining processes
while (true); do
printf "%s\n" "${PLIST}"
for PID in ${PLIST}; do
ISR=$(ps -p $PID --no-headers | wc -l)
	if [[ $ISR = 0 ]]; then
		PLIST=$(echo "${PLIST}" | sed "s/ $PID//")
		COUNT=$(( $COUNT-1 ))
	fi
printf "%s %s %s\n" "${PID}" "${ISR}" "${COUNT}"
done
if [[ $COUNT -eq 0  ]] ; then
	break
fi
printf "Waiting for final threads to finish...\n"
sleep 5
done


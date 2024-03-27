#!/bin/bash

if [ "$#" -lt 1 ]; then
	echo "Usage: $0 <processName(name of the executable)> "
	exit
fi

PROCESS_NAME=$1

check_main_process() {
	local pgrep_output
	pgrep_output=$(pgrep -x "$PROCESS_NAME")
#	echo $pgrep_output #echos the PID
	if [ -n "$pgrep_output" ]; then
		echo "process $PROCESS_NAME is running"
		return 0  # Process is running
	else
		echo "process $PROCESS_NAME is NOT running"
		return 1  # Process is not running
	fi
}

count_by_process_name() {
	local CUSTOM_PROCESS_NAME=$1
	local PID_COUNT
	local PID_OUT
	PID_OUT=$(($(pgrep -c -f "$CUSTOM_PROCESS_NAME") - 1))
	#sub 1 because it seems to count pgrep or something else
	echo "$PID_OUT"
}

restart_process() {
	gnome-terminal -- ./processKeepAlive.sh $PROCESS_NAME
	$PROCESS_NAME
}

while  true; do
	#for now warnings about "dmesg: read kernel buffer failed: Operation not permitted" are expected behavior while the process is already open somewhere"
	sleep 5
	keepalives=$(count_by_process_name "./processKeepAlive.sh $PROCESS_NAME")
	echo "$keepalives instances of ./processKeepAlive $PROCESS_NAME running"
	#we can use this to limit created instances running at once
	#more important executables might need more instances
	if ! check_main_process; then
		echo "$PROCESS_NAME not found in PIDs.\nRestarting $PROCESS_NAME..."
		restart_process
	fi

	if [ "$(dmesg | grep -i 'out of memory')" ]; then
		echo "$PROCESS_NAME killed due to OOM.\nRestarting $PROCESS_NAME..."
		restart_process
	fi
	
	if [ "$(dmesg | grep -i 'killed')" ]; then
		echo "$PROCESS_NAME was killed.\nRestarting $PROCESS_NAME..."
                restart_process
        fi

	sleep 60
done


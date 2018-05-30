#!/usr/bin/env bash
#
# hashgraphs - Scripts to aid in creating graphs from crypto mining processes.
#
# Copyright (c) 2018 overcookedpanda overcookedpanda@gmail.com
#
# This script relies on 'minerstats' available at https://github.com/overcookedpanda/minerstats
# Original author of minerstats:
# Copyright (c) 2018 johnnydiabetic johnnydiabetic@gmail.com
#
# The below example uses InfluxDB for its backend, but could be modified accordingly to use other databases.
#
# Enter needed system and db info below
#
DB_SERVER="testserver"
DB_USER="testuser"
DB_PASS="testpass"
DB_NAME="testdb"
WORKER_NAME=$(hostname)
MSPATH="/home/user/bin"
#
# Main function for writing stats to remote database (InfluxDB example)
#
STATS_WRITE() {
    curl -XPOST "$DB_SERVER/write?u=$DB_USER&p=$DB_PASS&db=$DB_NAME" --data-binary "$@"
}
#
# minerstats needs to be updated to include temperature output and power per card and you could avoid calling nvidia-smi
# as it may slow the system down on rigs with more than 6-8 gpus.
#
NVTEMP=($(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits))
NVPWR=($(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits))
GPU_COUNT=$(nvidia-smi -i 0 --query-gpu=count --format=csv,noheader,nounits)
# Pull total power draw of all cards
TDP=$($MSPATH/minerstats | jq -r .power)
# Check to make sure our output is a number
numcheck='^[0-9]+([.][0-9]+)?$'
# Grab hashrate from running miner in H/s
HASHRATE=$($MSPATH/minerstats | jq -r .hashrate )
#
# Start adding the stats to send to the db server
        # Get current hashrate in H/s
        if [[ $HASHRATE =~ $numcheck ]]; then
		PAYLOAD="current_hashrate,host=$WORKER_NAME value=$HASHRATE"
	fi
        # Get current total power draw from miner process (all cards combined)
	if [[ $TDP =~ $numcheck ]]; then
		TDPPAYLOAD="tdp,host=$WORKER_NAME value=$TDP"
		PAYLOAD="$PAYLOAD\n$TDPPAYLOAD"
	echo "--------------------------------------------------------------"
	echo " Current Performance: $HASHRATE H/s using $TDP watts."
	echo "--------------------------------------------------------------"
	echo " Individual Temperature and Power usage:                      "
	echo ""
	fi
	# Get individual temperatures and power for each card
	for (( i=0; i<$GPU_COUNT; i++)); do
		TEMPPAYLOAD="gpu_temp,host=$WORKER_NAME,gpu_device=$i value=${NVTEMP[i]}"
		PWRPAYLOAD="gpu_powerdraw,host=$WORKER_NAME,gpu_device=$i value=${NVPWR[i]}"
		PAYLOAD="$PAYLOAD\n$TEMPPAYLOAD\n$PWRPAYLOAD"
	echo " GPU$i ${NVTEMP[i]} C - ${NVPWR[i]} W"
	done
	echo "--------------------------------------------------------------"
PAYLOAD="$(echo -e $PAYLOAD)"
STATS_WRITE "$PAYLOAD"

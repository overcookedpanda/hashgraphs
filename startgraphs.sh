#!/usr/bin/env bash
echo " Starting hashgraphs, press Ctrl+C to exit."
while :
do
	echo "Sending metrics upstream.."
	./hashgraphs.sh
# EDIT THIS VALUE TO SET DELAY (15-30 recommended)
	sleep 30
done

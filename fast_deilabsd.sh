#!/bin/bash

logged=0

function check_DEI {
	res=$(nmcli -t dev wifi | grep ":DEI:") 
	if [ -z "$res" ]; then
		echo 0
	else
		echo 1
	fi
}

function handle_sigint {
	result=$(fast_deilabs out)

	echo "Exiting"
	echo $result
	exit
}

trap handle_sigint SIGINT
trap handle_sigint SIGTERM

echo "Started Fast DEILabs daemon service.\nLooking for DEI wifi"

while true; do
	if [ $logged -eq 0 ]; then
		if [ $(check_DEI) -eq 1 ]; then
			result=$(fast_deilabs in)
			error=$?

			if [ $error -eq 0 ]; then
				echo $result
				echo "DEI wifi detected, logged to DEILabs"
				logged=1
			else
				echo $result
				echo "DEI wifi detected but unable to login to DEILabs"
			fi
		else
			logged_out=0
			while [ $logged_out -eq 0 ]; do
				fast_deilabs out
				error=$?
				if [ $error -eq 0 ]; then
					echo "Logged out"
					logged_out=1
				fi
			done
			logged=0
		fi
	fi
	sleep 2
done
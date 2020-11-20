#!/bin/bash

install_dir="/usr/local/bin"
exec_name="mail_laboratori"
script_name="$exec_name.sh"

if [ "$EUID" -ne 0 ];  then
	echo "Please run as root"
	exit
fi

if [ $# -gt 0 ]; then
	if [ $1 = "clean" ]; then
		unlink "$install_dir/$exec_name"
		if [ $? -eq 0 ]; then
			echo "Removed link in $install_dir"
		fi
		exit
	fi
fi

chmod ugo+x $script_name

if [ $? -ne 0 ]; then
	echo "Errors changing $script_name permissions"
	echo "Installation failed"
	exit
fi

ln -s $(pwd)/$script_name $install_dir/$exec_name
if [ $? -ne 0 ]; then
	echo "Errors linking script to $install_dir/$exec_name"
	echo "Installation failed"
	exit 
fi
echo "Created link in $install_dir/$exec_name"
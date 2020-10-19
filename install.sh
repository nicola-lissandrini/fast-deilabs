#!/bin/bash

install_dir="/usr/local/bin"
exec_name="mail_laboratori"
script_name="$exec_name.sh"

ln -s $(pwd)/$script_name $install_dir/$exec_name
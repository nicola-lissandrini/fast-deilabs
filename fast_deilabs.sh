#!/bin/bash

host="https://deilabs.dei.unipd.it"
login_page="${host}/login"
home_page="${host}/home"
lab_in_out_page="${host}/laboratory_in_outs"

config_dir="$HOME/.config/fast_deilabs"
cookies_file="$config_dir/cookies.txt"
exit_file="$config_dir/exit_url"
configfile="$config_dir/setup.config"

# Check for config dir
if ! [[ -d "$config_dir" ]]; then
	mkdir -p $config_dir
fi

function usage {
	echo 
	echo "Automatically register to deilabs.dei.unipd.it"
	echo "  by Nicola Lissandrini <nicola.lissandrini@dei.unipd.it>"
	echo 
	echo
	echo "Usage: $0 [configuration] [in|out]"
	echo
	echo "  Configure:"
	echo "  	-n NAME 	Set DEI account name"
	echo "  	-l LAB 		Set current office name, format e.g.: 330 DEI/A"
	echo "  	-p PSW		Set user psw. WARNING: saved unencrypted. If you don't save the psw you will be prompted each time"
	echo "  	-r 		Reset password"
	echo "  	-h 		Show this help"
	echo 
	echo "  Register entry/exit:"
	echo "  	in  		Register entry with current configuration"
	echo "  	out 		Register exit with current configuration"
	echo
	echo
	echo "Troubleshoot:"
	echo "  * Packets needed: libio-socket-ssl-perl libnet-ssleay-perl perl sendemail"
	echo "  * You need to enable 'less secure apps' at https://myaccount.google.com/lesssecureapps"
	exit
}

function not_configured {
	echo "Configuration incomplete"
}

function parse_config {
	par=$1
	grep "^$par=" $configfile | cut -d "=" -f2
}

function save_config {
	echo "# Mail to laboratori@dei configuration file." > $configfile
	echo "name=$1" >> $configfile
	echo "lab=$2" >> $configfile
	echo "psw=$3" >> $configfile
}

function get_username {
	echo $1 | cut -d "@" -f1
}

function get_labs {
	grep -A 2 "<option" < /dev/stdin |\
	 paste - - - |\
	 sed -n 's/[ ]//p' |\
	 sed -n 's/.*<option value="\([0-9]*\)".*>\s*\(.*\)*\s*<\/option>.*/\1 "\2/p' |\
	 sed -n 's/[ \t]*$/"/p'
}

function get_token {
	tokenpage=$(wget --save-cookies ${cookies_file} \
		 			 --keep-session-cookies \
		 			 -O - "$login_page" 2> /dev/null)

	token=$(echo "$tokenpage" | grep _token | sed -n 's/.*value="\(.*\)".*/\1/p')
	echo $token
}

function do_login {
	token=$1
	email=$2
	password=$3
	login_result=$(wget --load-cookies ${cookies_file} \
						--keep-session-cookies \
						--save-cookies ${cookies_file} \
						--post-data "_token=${token}&email=${email}&password=${password}" \
						-O - "$login_page" 2> /dev/null)
}

function find_lab {
	token=$1
	lab=$2
	lab_list_result=$(wget --load-cookies ${cookies_file} \
						 --keep-session-cookies \
						 --save-cookies ${cookies_file} \
						 -O - "$lab_in_out_page" 2> /dev/null)

	# Check not already entered
	if ! [[ -z $(echo "$lab_list_result" | grep "Exit from") ]]; then
		entered_lab=$(echo "$lab_list_result" | grep "Exit from" | sed -n 's/.*Exit from \(.*\)".*/\1/p')
		echo "Already entered $entered_lab. Aborting"
		exit -1
	fi

	lab_ids=$(echo "$lab_list_result" | get_labs)

	# Get desired lab
	found_lab=$(echo "$lab_ids" | grep "$lab") 

	# Check if found exactly one
	if [[ -z "$found_lab" ]]; then
		echo "No laboratory matches the supplied label. Aborting"
		exit -1
	fi
	if [[ $(echo "$found_lab" | wc -l)  -gt 1 ]]; then
		echo "Multiple laboratories match the supplied label. Aborting"
		exit -1
	fi

	found_lab_id=$(echo "$found_lab" | sed -n 's/\(.*\) ".*"/\1/p')
	echo $found_lab_id
}

function enter_lab {
	token=$1
	found_lab_id=$2
	enter_lab_result=$(wget --load-cookies ${cookies_file} \
							--keep-session-cookies \
							--save-cookies ${cookies_file} \
							--post-data "_token=${token}&laboratory_id=${found_lab_id}" \
							-O - "$lab_in_out_page" 2> /dev/null)

	if ! [[ -z $(echo "$enter_lab_result" | grep "OK") ]]; then
		echo "Successfully entered lab $lab"
	else
		echo "Failed entering. Unexpected error occurred"
		exit
	fi
	# Store lab exit URL
	echo "$enter_lab_result" | grep -B 1 "edit_laboratory_in_outs_form" | paste - - | sed -n 's/.*action="\([^"]*\)".*/\1/p' > ${exit_file}
}

function exit_lab {
	token=$1

	if ! [[ -f ${exit_file} ]]; then
		echo "Not logged in from CLI. Aborting"
		exit -1
	fi

	exit_url=$(cat "$exit_file")
	exit_lab_result=$(wget --load-cookies ${cookies_file} \
						   --keep-session-cookies \
						   --save-cookies ${cookies_file} \
						   --post-data "_token=${token}&_method=PUT" \
						   -O - "$exit_url" 2> /dev/null)
	echo "$enter_lab_result" > bubu
	if ! [[ -z $(echo "$exit_lab_result" | grep "OK") ]]; then
		echo "Successfully exited"
	else
		echo "Failed exiting. Unexpected error occurred"
		exit
	fi
}

function lab_in {
	email=$1
	password=$2
	lab=$3

	# Get session token
	token=$(get_token)
	if [[ $? -ne 0 ]]; then
		echo "$token"
		exit $?
	fi

	# Do login
	do_login "$token" "$email" "$password"
	if [[ $? -ne 0 ]]; then
		exit $?
	fi

	# Find lab 

	lab_id=$(find_lab "$token" "$lab")
	if [[ $? -ne 0 ]]; then
		echo $lab_id
		exit $?
	fi

	# Enter lab
	enter_lab "$token" $lab_id
	if [[ $? -ne 0 ]]; then
		exit $?
	fi
}

function lab_out {
	email=$1
	password=$2
	lab=$3

	# Get session token
	token=$(get_token)
	if [[ $? -ne 0 ]]; then
		echo "$token"
		exit $?
	fi

	# Do login
	do_login "$token" "$email" "$password"
	if [[ $? -ne 0 ]]; then
		exit $?
	fi

	# Exit lab
	exit_lab "$token"
	if [[ $? -ne 0 ]]; then
		exit $?
	fi
}
# Check for existing configuration
configured=false
configuring=false

if [ -f $configfile ]; then
	config_name=$(parse_config name)
	config_lab=$(parse_config lab)
	config_psw=$(parse_config psw)
else
	touch $configfile
fi

# Check configuration
if  [[ ! -z $config_name ]] && [[ ! -z $config_lab ]]; then
	configured=true
fi

# Process general configuration
while getopts ":n:l:t:prhc" opt; do
  case ${opt} in
    n )
		configuring=true
		config_name=$OPTARG
		echo "Saving name $config_name"
      ;;
    l )
		configuring=true
		config_lab=$OPTARG
		echo "Saving lab $config_lab"
      ;;
	t )
		configuring=false
		event_time=$OPTARG
		;;
	p )
		configuring=true
		echo "WARNING: saving password unencrypted"
		echo -n "Enter DEI account password: "
		read -s config_psw
		echo
		;;
	r )
		configuring=true
		config_psw=
		echo "Password reset"
		;;
    c )
		configuring=true
		echo "Configuration settings:"
		echo "  Name: $config_name"
		echo "  Lab: $config_lab"
		if [[ -z $config_psw ]]; then
			echo "Password not saved"
		else
			echo "Password saved"
		fi
		if $configured; then
			echo "Configuration complete"
		else
			echo "Configuration incomplete"
		fi
		;;
    \?|h )
		usage
      ;;
  esac
done

save_config "$config_name" "$config_lab" "$config_psw" 


shift $((OPTIND -1))

if $configuring; then
	exit
fi
if ! $configured; then
	not_configured
	exit
fi
arg=$1

case $arg in
	in)
		lab_in "$config_name" "$config_psw" "$config_lab"
		;;
	out)
		lab_out "$config_name" "$config_psw" "$config_lab"
		;;
	*)
		echo "Invalid argument $arg"
		usage
		;;
esac
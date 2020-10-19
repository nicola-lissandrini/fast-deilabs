#!/bin/bash

mailto="laboratori@dei.unipd.it"
server="smtp.gmail.com"
opts="tls=yes"
subject="Accesso laboratori"

configfile="$HOME/.config/mail_laboratori.config"

function usage {
	echo 
	echo "Automatically send mail to laboratori@dei.unipd.it"
	echo "  by Nicola Lissandrini <nicola.lissandrini@dei.unipd.it>"
	echo 
	echo
	echo "Usage: $0 [configuration] [in|out]"
	echo
	echo "  Configure:"
	echo "  	-n NAME 	Set user name, format: First-name Last-name"
	echo "  	-l LAB 		Set current office name, format e.g.: DEI/A 330"
	echo "  	-m MAIL 	Set user email. WARNING: Only works with gmail"
	echo "  	-p PSW		Set user psw. WARNING: saved unencrypted. If you don't save the psw you will be prompted each time"
	echo "  	-r 		Reset password"
	echo "  	-d 		Disable prompting before sending"
	echo "  	-e 		Enable prompting before sending"
	echo "  	-h 		Show this help"
	echo 
	echo "  Send mail:"
	echo "  	in  		Send entry mail with current configuration"
	echo "  	out 		Send exit mail with current configuration"
	echo "  Options:"
	echo "		-t TIME 	Specify event time"
	echo
	echo
	echo "Troubleshoot:"
	echo "  * Packets needed: libio-socket-ssl-perl libnet-ssleay-perl perl sendemail"
	echo "  * You need to enable 'less secure apps' at https://myaccount.google.com/lesssecureapps"
	exit
}

function text_in {
	echo "Comunico il mio ingresso in ufficio $config_lab alle ore $1. \n\n$config_name"
}

function text_out {
	echo "Comunico la mia uscita dall'ufficio $config_lab alle ore $1.\n\n$config_name"
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
	echo "mail=$3" >> $configfile
	echo "psw=$4" >> $configfile
	echo "prompt=$5" >> $configfile
}

function get_username {
	echo $1 | cut -d "@" -f1
}

# Check for existing configuration
configured=false
configuring=false

if [ -f $configfile ]; then
	config_name=$(parse_config name)
	config_lab=$(parse_config lab)
	config_mail=$(parse_config mail)
	config_psw=$(parse_config psw)
	config_prompt=$(parse_config prompt)
else
	touch configfile
fi

# Check configuration
if  [[ ! -z $config_name ]] && [[ ! -z $config_lab ]] && [[ ! -z $config_mail ]]; then
	configured=true
fi


event_time=$(date "+%H:%M")

# Process general configuration
while getopts ":n:l:m:t:prdehc" opt; do
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
    m )
		configuring=true
		config_mail=$OPTARG
		echo "Saving mail $config_mail"
		;;
	t )
		configuring=false
		event_time=$OPTARG
		;;
	p )
		configuring=true
		echo "WARNING: saving password unencrypted"
		echo -n "Enter gmail password: "
		read -s config_psw
		echo
		;;
	r )
		configuring=true
		config_psw=
		echo "Password reset"
		;;
	d )
		configuring=true
		echo "Prompt disabled"
		config_prompt="disabled"
		;;
	e )
		configuring=true
		echo "Prompt enabled"
		config_prompt=
		;;
    c )
		configuring=true
		echo "Configuration settings:"
		echo "  Name: $config_name"
		echo "  Lab: $config_lab"
		echo "  Mail: $config_mail"
		if [[ -z $config_psw ]]; then
			echo "Password not saved"
		else
			echo "Password saved"
		fi
		if [[ -z $config_prompt ]]; then
			echo "Prompt enabled"
		else
			echo "Prompt disabled"
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

save_config "$config_name" "$config_lab" "$config_mail" "$config_psw" "$config_prompt"


shift $((OPTIND -1))

if $configuring; then
	exit
fi

arg=$1

case $arg in
	in)
		if ! $configured; then
			not_configured
		fi
		text=$(text_in "$event_time")
		;;
	out)
		if ! $configured; then
			not_configured
		fi
		text=$(text_out "$event_time")
		;;
	*)
		echo "Invalid argument $arg"
		usage
		;;
esac

# Send email 

# Prompt
if [[ -z $config_prompt ]]; then
	while true; do
		echo -e "Mail to be sent:\n$text\n"
	    read -p "Send to $mailto? [y/N] " yn
	    case $yn in
	        [Yy]* ) break;;
	        * ) echo "Not sending. Exiting"
				exit;;
	    esac
	done
fi

username=$(get_username $config_mail)

# check if password stored
if [[ -z $config_psw ]]; then
	echo -n "Enter gmail password: "
	read -s config_psw
	echo
fi

sendemail -f "$config_name <$config_mail>" -t $mailto -u "$subject" -cc "$config_name <$config_mail>" -m "$text" -s "$server" -o "$opts" -xu $username -xp $config_psw
if [[ $? -eq 0 ]]; then
	echo "Mail sent to $mailto"
else
	echo "Mail not sent. sendemail returned code $?"
fi
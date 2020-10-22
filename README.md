# mail_laboratori
Shorthand command to send entry and exit mail to laboratori@dei.unipd.it

## Installation
To install the script to path:
`sudo ./install.sh`

To clean the installation run:
`sudo ./install.sh clean`

## Usage

When entering or leaving one of the offices of one of the DEI buildings, 
run the following command to send an automatic message to laboratori@dei with the current time stamp:
`mail_laboratori [options] <in| out>`
where:
* `in`: Send entry mail with current configuration
* `out`: Send exit mail with current configuration

Options:
* `-t TIME`: Specify entry/exit time

## Configuring

Before used, the tool needs to be configured with the user first and last name, gmail account
and current office name by running the command with options:
* `-n NAME`: Set user name, format: First-name Last-name
* `-l LAB `: Set current office name, format e.g.: DEI/A 330
* `-m MAIL`: Set user email. WARNING: Only works with gmail
* `-p PSW `: Set user psw. WARNING: saved unencrypted. If you don't save the psw you will be prompted each time
* `-r` : Reset password
* `-d` : Disable prompting before sending
* `-e` : Enable prompting before sending
* `-h` : Show an help

## Troubleshoots

* Packets needed: libio-socket-ssl-perl libnet-ssleay-perl perl sendemail
* If you have two factor authentication (2FA) enabled you need to generate a specific password
from your Google account to be used uniquely for mail_laboratory. See https://support.google.com/accounts/answer/185833?hl=en for further information.

Please open an issue on github if you find any problem.

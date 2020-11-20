# Fast DEI-labs
Immediately register your entrance or exit from one of the DEI labs with one single command line and avoid logging in and choosing from the list every time. 

## Installation
To install the script to path:
`sudo ./install.sh`

To clean the installation run:
`sudo ./install.sh clean`

## Usage

When entering or leaving one of the offices of one of the DEI buildings, 
run the following command to automatically register to DEI labs:
`fast_deilabs [options] <in| out>`
where:
* `in`: Register entry with current configuration
* `out`: Register exit with current configuration

## Configuring

Before used, the tool needs to be configured with the user's DEI account name and password
and current lab name by running the command with options:
* `-n NAME`: Set DEI account name
* `-l LAB `: Set current lab name, format e.g.: 330 DEI/A.
* `-p PSW `: Set user psw. WARNING: saved unencrypted. If you don't save the psw you will be prompted each time
* `-r` : Reset password
* `-h` : Show an help

Please open an issue on github if you find any problem.
Legacy script `mail_laboratori` can be found in the corresponding branch

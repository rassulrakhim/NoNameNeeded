#!/bin/bash

# This script expects a ssh-user as first parameter
# And the private SSH key path as second parameter
# default key file path is ~/.ssh/id_rsa

CURR_PATH=$(pwd)

SSH_USER=$1
KEY_FILE="id_rsa"

usage () {
echo "Usage: ./bootstrap.sh ssh-user [key-file = id_rsa]"
exit 1
}

create_inventory () {
echo "---
USER_NAME: ${SSH_USER}
SSH_FILE_NAME: ${KEY_FILE}" > variables.yml

ansible-playbook create-inventory.yml
}

# check user
if [[ "$1" = "" ]]; then
	usage
fi

# use standard key file or not
if [[ "$2" != "" ]]; then
	KEY_FILE="$2"
fi

# check keyfile
if [[ ! -f "${HOME}/.ssh/${KEY_FILE}" ]]; then
	echo "${HOME}/.ssh/${KEY_FILE} not found."
	usage
fi

create_inventory

ansible-playbook -i multinode -l test network-bootstrap.yml

echo "end"
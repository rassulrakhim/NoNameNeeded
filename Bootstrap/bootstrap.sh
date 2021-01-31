#!/bin/bash

# for local setup use:
# the normal kolla setup, but replace / add:
# pip install "kolla-ansible==11.0.0"
# pip install python-openstackclient

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

ansible-playbook -i multinode -l baremetal network-bootstrap.yml

ansible-playbook -i multinode -l baremetal dependencys-bootstrap.yml

kolla-ansible -i multinode bootstrap-servers

kolla-ansible -i multinode prechecks

kolla-ansible -i multinode pull

kolla-ansible -i multinode deploy

kolla-ansible -i multinode post-deploy

if [[ ! -f "/etc/kolla/admin-openrc.sh" ]]; then
	echo "admin-openrc.sh not found."
	echo "failed to run post-deploy"
	exit 1
fi

sudo chown $USER:$USER /etc/kolla/admin-openrc.sh

source /etc/kolla/admin-openrc.sh

scp scripts/iptables-magic.sh \
	$SSH_USER@wally200.cit.tu-berlin.de:/home/$SSH_USER/iptables-magic.sh

ssh $SSH_USER@wally200.cit.tu-berlin.de /bin/bash <<EOF
	sudo ./iptables-magic.sh
EOF

./scripts/create-ext-network.sh

./scripts/import-images.sh

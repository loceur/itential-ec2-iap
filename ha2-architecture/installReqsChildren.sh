#!/bin/bash

echo -e "\n\n\nThis system is NOT ready to use.  The install script takes a while.  Give it a bit.\n\n" > /etc/motd

#extra ssh key insert via variable from terraform
echo -e "${extra_key}" >> /home/ec2-user/.ssh/authorized_keys
echo -e "${extra_key_priv}" >> /home/ec2-user/.ssh/id_ed25519

yum install git ansible-core unzip net-tools -y
ansible-galaxy collection install itential.deployer

#Alert that it's ready to be used cause it takes a while
echo "All services should be up and ready now.  Go for it!" | wall
echo "This system is ready to use.  The install script has completed." > /etc/motd

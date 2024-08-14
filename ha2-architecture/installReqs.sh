#!/bin/bash

echo -e "\n\n\n\nThis system is NOT ready to use.  The install script takes a while.  Give it a bit.\n\n" > /etc/motd

#extra ssh key insert via variable from terraform
echo -e "${extra_key}" >> /home/ec2-user/.ssh/authorized_keys
echo -e "${extra_key_priv}" >> /home/ec2-user/.ssh/id_ed25519

yum install git ansible-core unzip net-tools -y
sudo -u ec2-user ansible-galaxy collection install itential.deployer



# lets do some deployer work
sudo -u ec2-user mkdir /home/ec2-user/iap
sudo -u ec2-user mkdir /home/ec2-user/iap/files
sudo -u ec2-user mkdir /home/ec2-user/iap/inventories
sudo -u ec2-user mkdir /home/ec2-user/iap/inventories/dev

# pull IAG and IAP binaries stored on s3

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

#seems aws has issues with its first command sometimes?  Maybe a timing thing.  Dunno.  Dun care.
sudo -u ec2-user /usr/local/bin/aws s3 ls s3://itential-ec2-iap/
#download IAP and IAG
sudo -u ec2-user /usr/local/bin/aws s3 cp s3://itential-ec2-iap/automation_gateway-4.2.22+2023.3.6-py3-none-any.whl /home/ec2-user/iap/files
sudo -u ec2-user /usr/local/bin/aws s3 cp s3://itential-ec2-iap/itential-premium_2023.2.6.linux.x86_64.bin /home/ec2-user/iap/files

# make my inventories file
# TODO: figure out how to get the right IPs in this file
ips_csv="`aws ssm get-parameter --name "${SSM_PATH}" | jq .Parameter.Value | sed -e 's/"//g'`"
ips=($(echo $ips_csv $| tr "," "\n"))

main_ip="`aws ssm get-parameter --name "${SSM_main_PATH}" | jq .Parameter.Value | cut  -d'"' -f2`"



# keyfile for mongodb based on
# https://www.mongodb.com/docs/manual/tutorial/deploy-replica-set-with-keyfile-access-control/
sudo -u ec2-user openssl rand -base64 756 > /home/ec2-user/iap/files/mongo_auth_keyfile.pem


cat <<EOF >> /home/ec2-user/iap/inventories/dev/hosts
all:
  vars:
    ansible_user: ec2-user
    #ansible_ssh_private_key_file: ~/.ssh/pssup-key.pem
    iap_release: 2023.2
    prometheus: true
    prometheus_grafana: true
    # incorrect variable
    # grafana: true
    redis_replication: true
    redis_auth: true
    rabbitmq_cluster: true
    mongodb_replication: true
    mongodb_auth: true
    mongo_auth_keyfile_source: mongo_auth_keyfile.pem

  children:
    redis:
      hosts:
        #redis-host-1:
        $${ips[0]}:
        #redis-host-2:
        $${ips[1]}:
        #redis-host-3:
        $${ips[2]}:

# blank hosts file is needed for prometheus check
    rabbitmq:
      hosts:
#        rabbit-host-1:
#          ansible_host: $${ips[9]}
#        rabbit-host-2:
#          ansible_host: $${ips[10]}
#        rabbit-host-3:
#          ansible_host: $${ips[11]}

    mongodb:
      hosts:
        $${ips[3]}:
        $${ips[4]}:
        $${ips[5]}:

    platform:
      hosts:
        $${main_ip}:
        $${ips[6]}:
      vars:
        iap_bin_file: itential-premium_2023.2.6.linux.x86_64.bin
        # iap_tar_file: itential-config-service_2023.1.13.linux.x86_64.tar.gz
        configure_iap: true
        iap_configure_vault: false
        app_artifact: false
        #app_artifact_source_file: itential-app-artifacts-6.5.3-2023.1.5.tgz

    prometheus:
      hosts:
        $${ips[7]}:

    gateway:
      hosts:
        $${ips[8]}:
      vars:
        iag_release: 2023.2
        #iag_whl_file: automation_gateway-3.227.0+2023.1.57-py3-none-any.whl
        iag_whl_file: automation_gateway-4.2.22+2023.3.6-py3-none-any.whl
        iag_haproxy: true


EOF

chown ec2-user:ec2-user /home/ec2-user/iap/inventories/dev/hosts

#and now move to the right place

sudo -u ec2-user ln -s /home/ec2-user/iap/files /home/ec2-user/.ansible/collections/ansible_collections/itential/deployer/playbooks

ANSIBLE_HOST_KEY_CHECKING=FALSE

#now we need to do the labor of installing IAP from deployer

echo -n "Installing MongoDB..." | wall
sudo -u ec2-user ANSIBLE_HOST_KEY_CHECKING=FALSE ansible-playbook itential.deployer.mongodb -i /home/ec2-user/iap/inventories/dev/hosts
echo -n "Installing Redis..." | wall
sudo -u ec2-user ANSIBLE_HOST_KEY_CHECKING=FALSE ansible-playbook itential.deployer.redis -i /home/ec2-user/iap/inventories/dev/hosts
echo -n "Installing IAP..." | wall
sudo -u ec2-user ANSIBLE_HOST_KEY_CHECKING=FALSE ansible-playbook itential.deployer.iap -i /home/ec2-user/iap/inventories/dev/hosts
echo -n "Installing IAG..." | wall
sudo -u ec2-user ANSIBLE_HOST_KEY_CHECKING=FALSE ansible-playbook itential.deployer.gateway -i /home/ec2-user/iap/inventories/dev/hosts
echo -n "Installing Prometheus..." | wall
sudo -u ec2-user ANSIBLE_HOST_KEY_CHECKING=FALSE ansible-playbook itential.deployer.prometheus -i /home/ec2-user/iap/inventories/dev/hosts


#Alert that it's ready to be used cause it takes a while
echo "All services should be up and ready now.  Go for it!" | wall
echo "This system is ready to use.  The install script has completed." > /etc/motd

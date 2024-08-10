#!/bin/bash

echo "\n\n\n\nThis system is NOT ready to use.  The install script takes a while.  Give it a bit.\n\n" > /etc/motd

#extra ssh key insert via variable from terraform
echo -e "${extra_key}" >> /home/ec2-user/.ssh/authorized_keys
echo -e "${extra_key_priv}" >> /home/ec2-user/.ssh/id_ed25519

yum install git ansible-core unzip -y
ansible-galaxy collection install itential.deployer



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
sudo -u ec2-user cat <<EOF > /home/ec2-user/iap/inventories/dev/hosts

all:
  vars:
    iap_release: 2023.2
    ansible_user: ec2-user

  children:
    redis:
        hosts:
           `aws ssm get-parameter --name "${SSM_PATH}" | jq .Parameter.Value | sed -e 's/"//g' | cut -d, -f2`:

    mongodb:
        hosts:
            `aws ssm get-parameter --name "${SSM_PATH}" --debug | jq .Parameter.Value | sed -e 's/"//g' | cut -d, -f1`:

    platform:
        hosts:
            127.0.0.1:
        vars:
            iap_bin_file: itential-premium_2023.2.6.linux.x86_64.bin

    gateway:
        hosts:
            127.0.0.1:
        vars:
            iag_release: 2023.2
            iag_whl_file: automation_gateway-4.2.22+2023.3.6-py3-none-any.whl
EOF

#Alert that it's ready to be used cause it takes a while
echo "All services should be up and ready now.  Go for it!" | wall
echo "This system is ready to use.  The install script has completed." > /etc/motd

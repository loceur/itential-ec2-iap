
# How to build a network lab for the PM Team

This should be a quick and easy setup and teardown of lab environments for demoing and internal use.

NOTE: THE LAB DOES NOT SHUT ITSELF DOWN.  MAKE SURE YOU USE TERRAFORM TO DELETE THE ENVIRONMENT WHEN DONE.


## Requirements

AWS CLI : https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Terraform CLI: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

Git: https://github.com/git-guides/install-git


## Instructions

#### Configure AWS Authentication
```bash
aws configure
```

```sh-session
Access Key: [get from AWS]
Secret Key: [get from AWS]
Default region name: us-east-1
Default output format: <Enter>
```
#### Grab Terraform Scripts

```bash
git clone https://github.com/loceur/itential-ec2-clabs.git
```

### Start up the Environment

```bash
cd itential-ec2-clabs
terraform init
terraform apply -auto-approve
```

You should see something like this
```sh-session
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

instance-id = "i-05aa2c357fe28fbf0"
instance-public-dns = "ec2-52-91-145-82.compute-1.amazonaws.com"
```

#### (Optional) AWS Profiles

NOTE: if you use profiles for the aws cli, then you'll need to set the aws-profile var in terraform to be able to use the appropriate credentials
```bash
aws configure --profile=<PROFILE_NAME>
```

```bash
terraform apply -auto-approve -var="aws-profile=<PROFILE_NAME>"
```


#### SSH to Environment

Make sure that you have the shared SSH key that we're using for the labs.  Ask the PM team for it if you don't have it already.

```bash
chmod 400 PMTeam-us-east-1.pem
ssh -i PMTeam-us-east-1.pem ubuntu@<DNS from output>
```

#### (Optional) Wait for Services if you're faaast
At this stage you may be ahead of the cloud-init script.  You may need to wait a couple of minutes.  In my tests, it takes less than 5 minutes to complete.  If you are logged in to an ssh session, you will be alerted when the script has completed.

```bash
sudo docker images
```

When completed, you will see this:
```sh-session
ubuntu@ip-10-0-1-152:~$ sudo docker images
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
ceos         4.31.2F   e364cfff3c86   3 minutes ago   2.47GB
```
#### Run a Containerlab topology

```bash
cd ~/itential-pmlabs
sudo clab deploy
```
The 2 lab env takes roughly 1 minute to deploy
```sh-session
ubuntu@ip-10-0-1-152:~/itential-pmlabs$ sudo clab deploy
INFO[0000] Containerlab v0.52.0 started
INFO[0000] Parsing & checking topology file: helloworld.clab.yml
INFO[0000] Creating docker network: Name="clab", IPv4Subnet="172.20.20.0/24", IPv6Subnet="2001:172:20:20::/64", MTU=1500
INFO[0000] Creating lab directory: /home/ubuntu/itential-pmlabs/clab-helloWorld
INFO[0000] Creating container: "ceos2"
INFO[0000] Creating container: "ceos1"
INFO[0000] Running postdeploy actions for Arista cEOS 'ceos2' node
INFO[0000] Created link: ceos1:eth1 <--> ceos2:eth1
INFO[0000] Running postdeploy actions for Arista cEOS 'ceos1' node
INFO[0036] Adding containerlab host entries to /etc/hosts file
INFO[0036] Adding ssh config for containerlab nodes
+---+-----------------------+--------------+--------------+-------------+---------+----------------+----------------------+
| # |         Name          | Container ID |    Image     |    Kind     |  State  |  IPv4 Address  |     IPv6 Address     |
+---+-----------------------+--------------+--------------+-------------+---------+----------------+----------------------+
| 1 | clab-helloWorld-ceos1 | d389a94dea81 | ceos:4.31.2F | arista_ceos | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
| 2 | clab-helloWorld-ceos2 | 649857b946e0 | ceos:4.31.2F | arista_ceos | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
+---+-----------------------+--------------+--------------+-------------+---------+----------------+----------------------+
```

At this stage, you can run commands directly from the device, or you can setup an ssh tunnel and have at it.

#### (Optional) local commands

```bash
sudo clab exec -t helloworld.clab.yml --cmd "Cli -c'show ver'"
```
```sh-session
INFO[0000] Parsing & checking topology file: helloworld.clab.yml
INFO[0000] Executed command "Cli -cshow ver" on the node "clab-helloWorld-ceos1". stdout:
Arista cEOSLab
Hardware version:
Serial number: 914F165E0D5038F2866242027DF4E162
Hardware MAC address: 001c.7334.8fe0
System MAC address: 001c.7334.8fe0

Software image version: 4.31.2F-35442176.4312F (engineering build)
Architecture: x86_64
Internal build version: 4.31.2F-35442176.4312F
Internal build ID: 48bb2b78-5325-4a32-b124-dcd4e37fd3bc
Image format version: 1.0
Image optimization: None

cEOS tools version: (unknown)
Kernel version: 6.2.0-1018-aws

Uptime: 2 minutes
Total memory: 32856552 kB
Free memory: 28453308 kB

INFO[0000] Executed command "Cli -cshow ver" on the node "clab-helloWorld-ceos2". stdout:
Arista cEOSLab
Hardware version:
Serial number: 5B4B440586BAED2669A899998F55C2D3
Hardware MAC address: 001c.737f.ead1
System MAC address: 001c.737f.ead1

Software image version: 4.31.2F-35442176.4312F (engineering build)
Architecture: x86_64
Internal build version: 4.31.2F-35442176.4312F
Internal build ID: 48bb2b78-5325-4a32-b124-dcd4e37fd3bc
Image format version: 1.0
Image optimization: None

cEOS tools version: (unknown)
Kernel version: 6.2.0-1018-aws

Uptime: 2 minutes
Total memory: 32856552 kB
Free memory: 28442976 kB
```


#### (Optional) Access Switches from Laptop

Using ssh tunneling seems to be the easiest way to do things for OOB management.

```bash
sudo clab inspect
```
```sh-session
INFO[0000] Parsing & checking topology file: helloworld.clab.yml
+---+-----------------------+--------------+--------------+-------------+---------+----------------+----------------------+
| # |         Name          | Container ID |    Image     |    Kind     |  State  |  IPv4 Address  |     IPv6 Address     |
+---+-----------------------+--------------+--------------+-------------+---------+----------------+----------------------+
| 1 | clab-helloWorld-ceos1 | 66ec036c4530 | ceos:4.31.2F | arista_ceos | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
| 2 | clab-helloWorld-ceos2 | 03b5623eafaf | ceos:4.31.2F | arista_ceos | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
+---+-----------------------+--------------+--------------+-------------+---------+----------------+----------------------+

```

Copy the IP of the device you want to tunnel to.  Here's an example

```bash
ssh -L 20222:172.20.20.2:22 -i PMTeam-us-east-1.pem ubuntu@<DNS OR IP of host>
```

Now, just ssh to the tunnel
```sh-session
$ ssh admin@localhost -p 20222

(admin@localhost) Password:
Last login: Thu Mar 14 16:54:52 2024 from 172.20.20.1
ceos2>
```


### To Delete Resources (IMPORTANT)

From your terraform directory on your local device:

```bash
terraform destroy -auto-approve
```
This should take less than 1 minute.

```sh-session
aws_route_table_association.rta: Destroying... [id=rtbassoc-034a6072f7cc746ad]
aws_instance.instance: Destroying... [id=i-05aa2c357fe28fbf0]
aws_route_table_association.rta: Destruction complete after 0s
aws_route_table.rt: Destroying... [id=rtb-0972c45ce0243ec88]
aws_route_table.rt: Destruction complete after 1s
aws_internet_gateway.ig: Destroying... [id=igw-0420e9e9eeb31d7c3]
aws_instance.instance: Still destroying... [id=i-05aa2c357fe28fbf0, 10s elapsed]
aws_internet_gateway.ig: Still destroying... [id=igw-0420e9e9eeb31d7c3, 10s elapsed]
aws_instance.instance: Still destroying... [id=i-05aa2c357fe28fbf0, 20s elapsed]
aws_internet_gateway.ig: Still destroying... [id=igw-0420e9e9eeb31d7c3, 20s elapsed]
aws_instance.instance: Still destroying... [id=i-05aa2c357fe28fbf0, 30s elapsed]
aws_internet_gateway.ig: Still destroying... [id=igw-0420e9e9eeb31d7c3, 30s elapsed]
aws_internet_gateway.ig: Destruction complete after 38s
aws_instance.instance: Still destroying... [id=i-05aa2c357fe28fbf0, 40s elapsed]
aws_instance.instance: Destruction complete after 41s
aws_subnet.subnet: Destroying... [id=subnet-084555a302ad1580d]
aws_security_group.sg: Destroying... [id=sg-0ec85a14f79857e01]
aws_subnet.subnet: Destruction complete after 1s
aws_security_group.sg: Destruction complete after 1s
aws_vpc.vpc: Destroying... [id=vpc-02683daf1ac00f390]
aws_vpc.vpc: Destruction complete after 0s

Destroy complete! Resources: 7 destroyed.
```

Happy labbing!



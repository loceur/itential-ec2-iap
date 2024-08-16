provider "aws" {
  region  = "${var.aws-region}"
  profile = "${var.aws-profile}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

# Use this to get unique names for stuff
resource "random_id" "id" {
	  byte_length = 4
}

#ssh key stuff for ansible to use once deployed
resource "tls_private_key" "sshkey" {
   algorithm = "ED25519"
 }

resource "aws_key_pair" "deployer" {
  key_name   = "terraform-ssh-key-${random_id.id.hex}"
  public_key = tls_private_key.sshkey.public_key_openssh
}

#This should create your usable ssh key as sshkey-name in the terraform working dir
# where you ran terraform apply
resource "local_sensitive_file" "this" {
  content  = tls_private_key.sshkey.private_key_openssh
  filename = "${path.cwd}/sshkey-${aws_key_pair.deployer.key_name}"
}

resource "aws_instance" "instance_main" {
  ami                         = "${var.instance-ami-rhel}"
  instance_type               = "${var.instance-type-t2large}"
  iam_instance_profile        = data.aws_iam_instance_profile.instance_profile.name
  key_name                    = "${var.instance-key-name != "" ? var.instance-key-name : ""}"
  associate_public_ip_address = "${var.instance-associate-public-ip}"
  # user_data                 = "${file("${var.user-data-script}")}"
   user_data                   = templatefile("${var.user-data-script}", 
                                  {
                                    extra_key = aws_key_pair.deployer.public_key,
                                    extra_key_priv = tls_private_key.sshkey.private_key_openssh,
                                    SSM_PATH = "/ec2/ips-${random_id.id.hex}",
                                    SSM_main_PATH = "/ec2/mainip-${random_id.id.hex}"
                                  }
                                  ) 
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  subnet_id                   = "${aws_subnet.subnet.id}"
  tags = {
    Name = "${random_id.id.hex}-${var.instance-tag-name}"
  }
}

resource "aws_instance" "instance_children" {
  ami                         = "${var.instance-ami-rhel}"
  instance_type               = "${var.instance-type-t2large}"
  iam_instance_profile        = data.aws_iam_instance_profile.instance_profile.name
  key_name                    = "${var.instance-key-name != "" ? var.instance-key-name : ""}"
  associate_public_ip_address = "${var.instance-associate-public-ip}"
  # user_data                 = "${file("${var.user-data-script}")}"
   user_data                   = templatefile("${var.user-data-script-children}", 
                                  {
                                    extra_key = aws_key_pair.deployer.public_key,
                                    extra_key_priv = tls_private_key.sshkey.private_key_openssh
                                  }
                                  ) 
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  subnet_id                   = "${aws_subnet.subnet.id}"
  count                       = 9
  tags = {
    Name = "${random_id.id.hex}-${var.instance-tag-name}"
  }
}

#lets store the private IPs for our ansible script to use later

resource "aws_ssm_parameter" "ips" {
  name  = "/ec2/ips-${random_id.id.hex}"
  type  = "StringList"
  value = join(",",aws_instance.instance_children.*.private_ip)
}
resource "aws_ssm_parameter" "main_ip" {
  name  = "/ec2/mainip-${random_id.id.hex}"
  type  = "String"
  value = "${aws_instance.instance_main.private_ip}"
}


resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc-cidr-block}"
  enable_dns_hostnames = true

  tags = {
    Name = "${random_id.id.hex}-${var.vpc-tag-name}"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${random_id.id.hex}-${var.ig-tag-name}"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet-cidr-block}"

  tags = {
    Name = "${random_id.id.hex}-${var.subnet-tag-name}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.id}"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.rt.id}"
}

resource "aws_security_group" "sg" {
  name   = "${var.sg-tag-name}"
  vpc_id = "${aws_vpc.vpc.id}"

  #ssh
  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "22"
    to_port     = "22"
  }
  #http IAP/Grafana
  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "3000"
    to_port     = "3000"
  }
  #http IAG
  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "8083"
    to_port     = "8083"
  }
  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = "9090"
    to_port     = "9090"
  }
  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = "27017"
    to_port     = "27017"
  }

  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = "6379"
    to_port     = "6379"
  }

  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = "26379"
    to_port     = "26379"
  }

  # Prometheus needs
  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = "9100"
    to_port     = "9100"
  }

  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = "9216"
    to_port     = "9216"
  }

  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = "9121"
    to_port     = "9121"
  }
  ingress {
    
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = "9256"
    to_port     = "9256"
  }



  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    to_port     = "0"
  }

  tags = {
    Name = "${random_id.id.hex}-${var.sg-tag-name}"
  }
}

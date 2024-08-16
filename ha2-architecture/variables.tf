variable "aws-region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws-profile" {
  description = "The name of the AWS shared credentials account."
  type        = string
  default     = "default"
}

variable "aws-access-key" {
  description = "AWS provided access key token for account to run this plan."
  type        = string
  default     = "NO_ACCESS_KEY"
}

variable "aws-secret-key" {
  description = "AWS provided access key token for account to run this plan."
  type        = string
  default     = "NO_SECRET_KEY"
}

variable "instance-ami" {
  description = "The AMI (Amazon Machine Image) that identifies the instance"
  type        = string
  default     = "ami-07d9b9ddc6cd8dd30"
}
variable "instance-ami-mongodb" {
  description = "AWS 2023 AMI"
  type        = string
  # Amazon Linux 2023
  default      = "ami-0ae8f15ae66fe8cda"
  #default     = "ami-07d9b9ddc6cd8dd30"
}
variable "instance-ami-rhel" {
  description = "RHEL 9 Standard"
  type        = string
  default     = "ami-0583d8c7a9c35822c"
}

variable "instance-type" {
  description = "The instance type to be used"
  type        = string
  default     = "t2.2xlarge"
}
variable "instance-type-t2large" {
  description = "The instance type to be used"
  type        = string
  default     = "t2.large"
}

variable "instance-key-name" {
  description = "The name of the SSH key to associate to the instance. Note that the key must exist already."
  type        = string
  default     = "PMTeam-us-east-1"
}

variable "iam-role-name" {
  description = "The IAM role to assign to the instance"
  type        = string
  default     = ""
}

variable "instance-associate-public-ip" {
  description = "Defines if the EC2 instance has a public IP address."
  type        = string
  default     = "true"
}

variable "user-data-script" {
  description = "The filepath to the user-data script, that is executed upon spinning up the instance"
  type        = string
  default     = "./installReqs.sh"
}

variable "user-data-script-children" {
  description = "The filepath to the user-data script, that is executed upon spinning up the instance"
  type        = string
  default     = "./installReqsChildren.sh"
}

variable "instance-tag-name" {
  description = "instance-tag-name"
  type        = string
  default     = "EC2-instance-created-with-terraform"
}

variable "vpc-cidr-block" {
  description = "The CIDR block to associate to the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet-cidr-block" {
  description = "The CIDR block to associate to the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpc-tag-name" {
  description = "The Name to apply to the VPC"
  type        = string
  default     = "VPC-created-with-terraform"
}

variable "ig-tag-name" {
  description = "The name to apply to the Internet gateway tag"
  type        = string
  default     = "aws-ig-created-with-terraform"
}

variable "subnet-tag-name" {
  description = "The Name to apply to the VPN"
  type        = string
  default     = "VPN-created-with-terraform"
}

variable "sg-tag-name" {
  description = "The Name to apply to the security group"
  type        = string
  default     = "SG-created-with-terraform"
}

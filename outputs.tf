output "instance-id" {
  description = "The EC2 instance ID"
  value       = "${aws_instance.instance_main.id}"
}
output "instance-private-ip-children" {
  description = "The EC2 instance private DNS for children"
  value       = "${aws_instance.instance_children.*.private_ip}"
}

output "instance-public-dns" {
  description = "The EC2 instance public DNS"
  value       = "${aws_instance.instance_main.public_dns}"
}
output "instance-public-dns-children" {
  description = "The EC2 instance public DNS"
  value       = "${aws_instance.instance_children.*.public_dns}"
}
output "instructions" {
  value = <<EOT
  ssh -i sshkey-terraform-ssh-key ec2-user@${aws_instance.instance_main.public_dns}
  http://${aws_instance.instance_main.public_dns}:3000/
  User: admin@pronghorn Pass: admin  
  EOT
}
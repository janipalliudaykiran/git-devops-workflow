output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.lab.id
}

output "private_ip" {
  description = "Private IPv4 address of the instance"
  value       = aws_instance.lab.private_ip
}

output "public_ip" {
  description = "Public IPv4 address assigned to the instance"
  value       = aws_instance.lab.public_ip
}

output "ami_id" {
  description = "Amazon Linux 2023 AMI selected by Terraform"
  value       = data.aws_ami.al2023.id
}

output "security_group_id" {
  description = "Security group attached to the instance"
  value       = aws_security_group.ec2.id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IPv4 address"
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "URL of the web application"
  value       = "http://${aws_instance.web.public_ip}"
}

output "health_url" {
  description = "URL of the health endpoint"
  value       = "http://${aws_instance.web.public_ip}/health"
}

output "security_group_id" {
  description = "Web server security group ID"
  value       = aws_security_group.web.id
}

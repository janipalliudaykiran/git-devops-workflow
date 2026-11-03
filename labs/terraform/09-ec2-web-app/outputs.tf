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

output "alerts_topic_arn" {
  description = "SNS topic ARN for web application alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cpu_alarm_name" {
  description = "CloudWatch CPU alarm name"
  value       = aws_cloudwatch_metric_alarm.web_cpu_high.alarm_name
}

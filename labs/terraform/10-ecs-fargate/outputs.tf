output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.app.arn
}

output "container_image_uri" {
  description = "Exact ECR image used"
  value       = data.aws_ecr_image.app.image_uri
}

output "cloudwatch_log_group" {
  description = "Container log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "security_group_id" {
  description = "Security group attached to the tasks"
  value       = aws_security_group.tasks.id
}

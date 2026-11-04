variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_name" {
  description = "Name tag of the existing VPC"
  type        = string
  default     = "devops-codex-lab"
}

variable "public_subnet_1_name" {
  description = "First public subnet name"
  type        = string
  default     = "devops-codex-lab-public-1"
}

variable "public_subnet_2_name" {
  description = "Second public subnet name"
  type        = string
  default     = "devops-codex-lab-public-2"
}

variable "ecr_repository_name" {
  description = "Existing ECR repository"
  type        = string
  default     = "devops-python-app"
}

variable "image_tag" {
  description = "Existing working web application image tag"
  type        = string

  validation {
    condition     = length(trimspace(var.image_tag)) > 0
    error_message = "An existing ECR image tag is required."
  }
}

variable "allowed_client_cidr" {
  description = "Your public IPv4 address in CIDR /32 format"
  type        = string

  validation {
    condition = (
      can(cidrhost(var.allowed_client_cidr, 0)) &&
      endswith(var.allowed_client_cidr, "/32")
    )

    error_message = "Provide a valid single IPv4 address in /32 CIDR format."
  }
}

variable "simulate_deployment_failure" {
  description = "Use a nonexistent ECR image to test ECS failure recovery"
  type        = bool
  default     = false
}

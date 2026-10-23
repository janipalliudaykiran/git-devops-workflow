variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix for the network resources"
  type        = string
  default     = "devops-codex-lab"
}

variable "vpc_cidr" {
  description = "IP address range for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR ranges for the two public subnets"
  type        = list(string)

  default = [
    "10.20.1.0/24",
    "10.20.2.0/24"
  ]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Provide exactly two public subnet CIDR ranges."
  }
}

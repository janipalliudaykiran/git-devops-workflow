variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_name" {
  description = "Name tag of the existing VPC"
  type        = string
  default     = "devops-codex-lab"
}

variable "public_subnet_name" {
  description = "Name tag of the existing public subnet"
  type        = string
  default     = "devops-codex-lab-public-1"
}

variable "instance_name" {
  description = "Name of the EC2 test instance"
  type        = string
  default     = "devops-codex-ssm-lab"
}

variable "instance_type" {
  description = "EC2 instance type for the lab"
  type        = string
  default     = "t3.micro"
}

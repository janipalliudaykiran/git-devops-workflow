variable "aws_region" {
  description = "AWS region for the web server"
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
  description = "Name of the web server"
  type        = string
  default     = "devops-codex-web-demo"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

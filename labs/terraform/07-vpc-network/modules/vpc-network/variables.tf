variable "name" {
  description = "Name prefix for network resources"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR range for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR ranges for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "The module requires exactly two public subnet CIDRs."
  }
}

variable "availability_zones" {
  description = "Availability Zones for the subnets"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "The module requires exactly two Availability Zones."
  }
}

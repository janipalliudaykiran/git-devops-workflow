output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc_network.vpc_id
}

output "vpc_cidr" {
  description = "CIDR range of the VPC"
  value       = module.vpc_network.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the two public subnets"
  value       = module.vpc_network.public_subnet_ids
}

output "public_subnet_availability_zones" {
  description = "Availability Zones of the public subnets"
  value       = module.vpc_network.public_subnet_availability_zones
}

output "internet_gateway_id" {
  description = "ID of the attached Internet Gateway"
  value       = module.vpc_network.internet_gateway_id
}

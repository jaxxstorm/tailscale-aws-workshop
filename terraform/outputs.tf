output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = module.db.db_instance_endpoint
}

output "db_name" {
  description = "RDS database name"
  value       = module.db.db_instance_name
}

output "db_username" {
  description = "RDS database username"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "db_password" {
  description = "RDS database password"
  value       = random_password.db_password.result
  sensitive   = true
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "tailscale-workshop-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name    = "rds-subnet-group"
    Project = "tailscale-workshop"
  }
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = "tailscale-workshop-db"

  engine               = "postgres"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "workshopdb"
  username = "dbadmin"
  password = random_password.db_password.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Disable backups and multi-AZ for workshop (not recommended for production)
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false

  tags = {
    Project = "tailscale-workshop"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "rds-sg-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
    description = "PostgreSQL access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name    = "rds-security-group"
    Project = "tailscale-workshop"
  }
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

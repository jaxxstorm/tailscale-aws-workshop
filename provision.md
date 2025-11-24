# Provision Infrastructure

In order to ease the process of provisioning an environment we need to connect to, we'll use [Terraform](https://www.terraform.io/) to provision a basic AWS environment with the following components:

- **VPC following AWS best practices** including both private and public subnets:
  - The **public subnet** will have an Internet Gateway, allowing resources to communicate with the public internet
  - The **private subnet** will have a NAT Gateway, enabling outbound internet connectivity while keeping resources isolated
- **RDS PostgreSQL database** deployed inside the private subnet, completely inaccessible from the public internet

This setup represents a common real-world scenario where databases and other sensitive resources are isolated in private subnets for security.

## Get Started with Terraform

### Create a New Directory

First, create a new directory for your Terraform configuration:

```bash
mkdir tailscale-aws-workshop
cd tailscale-aws-workshop
```

### Create a `providers.tf`

Create a file called `providers.tf` with the following content:

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
```

These are the required providers we'll use throughout this workshop. The AWS provider enables interaction with AWS services, and the cloudinit provider will be used later for configuring EC2 instances.

### Initialize Terraform

Initialize your Terraform workspace to download the required providers:

```bash
terraform init
```

### Create a VPC

Create a file called `vpc.tf` with the following content:

```hcl
locals {
  vpc_cidr            = "172.16.0.0/16"
  vpc_private_subnets = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]
  vpc_public_subnets  = ["172.16.3.0/24", "172.16.4.0/24", "172.16.5.0/24"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name               = "tailscale-workshop-vpc"
  cidr               = local.vpc_cidr
  enable_nat_gateway = true
  single_nat_gateway = true  # Use a single NAT gateway to save costs

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = local.vpc_private_subnets
  public_subnets  = local.vpc_public_subnets

  tags = {
    Project = "tailscale-workshop"
  }
}
```

This configuration creates:
- A VPC with CIDR block `172.16.0.0/16`
- Three private subnets across different availability zones
- Three public subnets across different availability zones
- A NAT Gateway for outbound connectivity from private subnets

### Apply the VPC Configuration

Run Terraform to create the VPC:

```bash
terraform apply
```

Review the planned changes and type `yes` to confirm. Wait for the VPC creation to complete (this may take a few minutes due to the NAT Gateway).

### Create a Database

Now create a file called `rds.tf` with the following content to provision an RDS PostgreSQL instance inside your private subnet:

```hcl
resource "random_password" "db_password" {
  length  = 16
  special = true
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = "tailscale-workshop-db"

  engine               = "postgres"
  engine_version       = "16.3"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "workshopdb"
  username = "dbadmin"
  password = random_password.db_password.result
  port     = 5432

  db_subnet_group_name   = module.vpc.database_subnet_group_name
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
```

You'll also need to add the random provider to your `providers.tf`. Update it to include:

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
```

This RDS configuration creates:
- A PostgreSQL 16.3 database instance on a `db.t3.micro` instance (suitable for testing)
- A randomly generated secure password for the database
- A security group that allows PostgreSQL traffic (port 5432) from within the VPC
- The database is placed in the private subnets created by the VPC module
- Outputs for the database connection details (endpoint, name, username, and password)

### Update the VPC Configuration

The RDS module needs database subnets. Update your `vpc.tf` to include database subnet configuration:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name               = "tailscale-workshop-vpc"
  cidr               = local.vpc_cidr
  enable_nat_gateway = true
  single_nat_gateway = true

  azs              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets  = local.vpc_private_subnets
  public_subnets   = local.vpc_public_subnets
  database_subnets = local.vpc_private_subnets

  create_database_subnet_group = true

  tags = {
    Project = "tailscale-workshop"
  }
}
```

### Apply the Database Configuration

Run Terraform again to create the RDS instance:

```bash
terraform init  # Re-initialize to download the random provider
terraform apply
```

Review the changes and type `yes` to confirm. The RDS instance will take several minutes to provision.

### Verify the Database Credentials

Once the apply completes, you can view your database connection details:

```bash
terraform output db_endpoint
terraform output db_name
terraform output -raw db_password
```

**Important**: Note that the database is only accessible from within the VPC. In the next section, we'll use Tailscale to securely connect to it.
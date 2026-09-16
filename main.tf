terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1" # Closest AWS region to Nigeria / West Africa
}

# --- 1. NETWORK ISOLATION ---
resource "aws_vpc" "novapay_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "novapay-vpc", Environment = "staging" }
}

resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.novapay_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  tags              = { Name = "novapay-private-db-a" }
}

resource "aws_subnet" "private_db_b" {
  vpc_id            = aws_vpc.novapay_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
  tags              = { Name = "novapay-private-db-b" }
}

# --- 2. MANAGED DATASTORE (RDS PostgreSQL) ---
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "novapay-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]
}

resource "aws_security_group" "db_sg" {
  name        = "novapay-db-sg"
  description = "Allow inbound traffic from application compute layer only"
  vpc_id      = aws_vpc.novapay_vpc.id

  ingress {
    description     = "PostgreSQL from App Tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "novapay-app-sg"
  description = "Security group for App compute layer"
  vpc_id      = aws_vpc.novapay_vpc.id
}

resource "aws_db_instance" "wallet_db" {
  identifier             = "novapay-wallet-db"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t4g.micro"
  db_name                = "novapay_db"
  username               = "novapay_admin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  storage_encrypted      = true
  skip_final_snapshot    = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

# --- 3. SECRETS MANAGER RESOURCE ---
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "novapay/wallet/db-credentials"
  recovery_window_in_days = 0
}

# --- 4. LEAST-PRIVILEGE IAM ROLE & POLICY ---
resource "aws_iam_role" "app_execution_role" {
  name = "novapay-app-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "app_secrets_policy" {
  name        = "novapay-app-secrets-read"
  description = "Scoped read access specifically for NovaPay DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [aws_secretsmanager_secret.db_credentials.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_secrets_attach" {
  role       = aws_iam_role.app_execution_role.name
  policy_arn = aws_iam_policy.app_secrets_policy.arn
}
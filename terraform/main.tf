# Main Terraform Configuration for PGNi Infrastructure
# This file orchestrates all infrastructure components

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Optional: Configure backend for state management
  # backend "s3" {
  #   bucket = "pgni-terraform-state"
  #   key    = "infrastructure/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Environment = var.environment
      }
    )
  }
}

# Get current AWS account information
data "aws_caller_identity" "current" {}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate random password for database if not provided
resource "random_password" "db_password" {
  count   = var.db_password == "" ? 1 : 0
  length  = 20
  special = true
  override_special = "!#$%^&*()-_=+[]{}:?"
}

# Generate random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Local variables
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  db_password = var.db_password != "" ? var.db_password : random_password.db_password[0].result
  
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      CreatedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  )
}


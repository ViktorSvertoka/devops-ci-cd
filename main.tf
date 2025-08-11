terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 Backend Module
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "victorsvertoka-terraform-state-lesson-7"
  table_name  = "terraform-locks"
}

# VPC Module
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_name           = "lesson-7-vpc"
}

# ECR Module
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-django-app"
  scan_on_push = true
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name    = "lesson-7-eks-cluster"
  cluster_version = "1.28"
  
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  
  node_group_name         = "lesson-7-nodes"
  node_group_capacity     = "t3.medium"
  node_group_min_size     = 2
  node_group_max_size     = 6
  node_group_desired_size = 2
}
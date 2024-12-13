terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80.0"
    }
  }

  backend "s3" {
    bucket = "tfpocbucket001"
    key    = "k8s/eks/eks-module/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  region = "eu-north-1"
  name   = "eks-fargate"
}

provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "${local.name}-vpc"
  cidr           = "10.0.0.0/16"
  azs            = data.aws_availability_zones.available.names[*]
  public_subnets = [ "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24" ]
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${local.name}-cluster"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # Create an IAM role for the cluster
  create_iam_role = true

  fargate_profiles = [
    {
      name                   = "${local.name}-profile"
      selectors              = [{ namespace = "default" }]
      pod_execution_role_arn = module.eks.fargate_pod_execution_role_arn
    }
  ]

  eks_managed_node_groups = [] # No managed nodes

  tags = {
    Environment = "learning"
    Name        = local.name
    Terraform   = "true"
  }
}



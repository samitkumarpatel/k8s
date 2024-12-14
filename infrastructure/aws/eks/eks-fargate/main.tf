terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80.0"
    }
  }

  backend "s3" {
    bucket = "tfpocbucket001"
    key    = "k8s/eks/eks-fargate/terraform.tfstate"
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

# VPC Configuration
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "eks_private" {
  count                   = 3
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 3, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name}-private-${count.index + 1}"
  }
}

# EKS IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.name}-cluster-im_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
      }
    ]
  })

  tags = {
    Name = "${local.name}-cluster-im-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${local.name}-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.eks_private[*].id
  }

  tags = {
    Name = "${local.name}-cluster"
  }
}

# Fargate Profile
resource "aws_eks_fargate_profile" "default" {
  cluster_name         = aws_eks_cluster.eks_cluster.name
  fargate_profile_name = "default"

  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn

  subnet_ids = aws_subnet.eks_private[*].id

  selector {
    namespace = "default"
  }

  tags = {
    Name = "${local.name}-fargate-profile"
  }
}

resource "aws_iam_role" "eks_fargate_pod_execution_role" {
  name = "${local.name}-fargate-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "eks-fargate-pods.amazonaws.com" }
      }
    ]
  })

  tags = {
    Name = "${local.name}-fargate-pod-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "fargate_execution_policy" {
  role       = aws_iam_role.eks_fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "fargate_profile_name" {
  value = aws_eks_fargate_profile.default.fargate_profile_name
}

output "kubeconfig" {
  value = <<EOT
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        server: ${aws_eks_cluster.eks_cluster.endpoint}
        certificate-authority-data: ${aws_eks_cluster.eks_cluster.certificate_authority[0].data}
      name: eks-cluster
    contexts:
    - context:
        cluster: eks-cluster
        user: eks-user
      name: eks-context
    current-context: eks-context
    users:
    - name: eks-user
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1
          command: aws
          args:
          - "eks"
          - "get-token"
          - "--region"
          - "eu-north-1"
          - "--cluster-name"
          - "${aws_eks_cluster.eks_cluster.name}"
          interactiveMode: "Never"
  EOT
}
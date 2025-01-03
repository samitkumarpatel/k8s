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

# VPC
resource "aws_vpc" "eksfargate_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name}-vpc"
  }
}


# Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnets
resource "aws_subnet" "eksfargate_public_subnet" {
  count = 3

  vpc_id                  = aws_vpc.eksfargate_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eksfargate_vpc.cidr_block, 3, count.index + 3)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${local.name}-public-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "eksfargate_private_subnet" {
  count = 3

  vpc_id                  = aws_vpc.eksfargate_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eksfargate_vpc.cidr_block, 3, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    "Name"                                      = "${local.name}-private-${count.index + 1}"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "eksfargate_igw" {
  vpc_id = aws_vpc.eksfargate_vpc.id

  tags = {
    Name = "${local.name}-igw"
  }
}

# Route Table for Public Subnets with Internet Gateway
resource "aws_route_table" "eksfargate_public_rt" {
  vpc_id = aws_vpc.eksfargate_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eksfargate_igw.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "eks_public_rt_assoc" {
  count          = 3
  subnet_id      = aws_subnet.eksfargate_public_subnet[count.index].id
  route_table_id = aws_route_table.eksfargate_public_rt.id
}


# NAT Gateway
resource "aws_eip" "eksfargate_eip" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.eksfargate_igw ]
  
  tags = {
    Name = "${local.name}-nat-eip"
  }
}


resource "aws_nat_gateway" "eksfargate_nat" {
  allocation_id = aws_eip.eksfargate_eip.id
  subnet_id     = aws_subnet.eksfargate_public_subnet[0].id

  tags = {
    Name = "${local.name}-nat"
  }

  depends_on = [aws_internet_gateway.eksfargate_igw]
}

# Route Table for Private Subnets with NAT Gateway
resource "aws_route_table" "eksfargate_private_rt" {
  vpc_id = aws_vpc.eksfargate_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eksfargate_nat.id
  }

  tags = {
    Name = "${local.name}-private-rt"
  }

}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "eksfargate_private_rt_assoc" {
  count          = 3
  subnet_id      = aws_subnet.eksfargate_private_subnet[count.index].id
  route_table_id = aws_route_table.eksfargate_private_rt.id
}


# EKS iAM Role
data "aws_iam_policy_document" "eks-demo-cluster-admin-role-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks-demo-cluster-admin-role-01" {
  name               = "${local.name}-admin-role-01"
  assume_role_policy = data.aws_iam_policy_document.eks-demo-cluster-admin-role-policy.json
}

resource "aws_iam_role_policy_attachment" "eks-demo-cluster-01-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-demo-cluster-admin-role-01.name
}

resource "aws_iam_role_policy_attachment" "eks-demo-cluster-01-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-demo-cluster-admin-role-01.name
}



# EKS Cluster
resource "aws_eks_cluster" "eksfargate_cluster" {
  name      = "${local.name}-cluster"
  version  = 1.31 
  role_arn  = aws_iam_role.eks-demo-cluster-admin-role-01.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    subnet_ids = concat(
      aws_subnet.eksfargate_private_subnet[*].id, 
      aws_subnet.eksfargate_public_subnet[*].id
    )
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }


  tags = {
    Name = "${local.name}-cluster"
  }
}

resource "aws_eks_addon" "eks-demo-addon-coredns" {
  cluster_name                = aws_eks_cluster.eksfargate_cluster.name
  addon_name                  = "coredns"
  #addon_version               = "v1.10.1-eksbuild.4" 
  resolve_conflicts_on_create = "OVERWRITE" 
}

resource "aws_eks_addon" "eks-demo-addon-kube-proxy" {
  cluster_name                = aws_eks_cluster.eksfargate_cluster.name
  addon_name                  = "kube-proxy"
  #addon_version               = "v1.28.2-eksbuild.2" 
  resolve_conflicts_on_create = "OVERWRITE" 
}

resource "aws_eks_addon" "eks-demo-addon-vpc-cni" {
  cluster_name                = aws_eks_cluster.eksfargate_cluster.name
  addon_name                  = "vpc-cni"
  #addon_version               = "v1.15.1-eksbuild.1" 
  resolve_conflicts_on_create = "OVERWRITE" 
}



# Fargate profile
resource "aws_iam_role" "eksfargate_profile" {
  name = "${local.name}-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eksfargate_iam_policy_profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eksfargate_profile.name
}

resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.eksfargate_cluster.name
  fargate_profile_name   = "${local.name}-kube-system"
  
  pod_execution_role_arn = aws_iam_role.eksfargate_profile.arn
  
  subnet_ids = aws_subnet.eksfargate_private_subnet[*].id

  selector {
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kube-dns"
    }
  }
  
  selector {
    namespace = "default"
  }

}


# Output
output "cluster_endpoint" {
  value = aws_eks_cluster.eksfargate_cluster.endpoint
}

output "kubeconfig" {
  value = <<EOT
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        server: ${aws_eks_cluster.eksfargate_cluster.endpoint}
        certificate-authority-data: ${aws_eks_cluster.eksfargate_cluster.certificate_authority[0].data}
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
          - "${aws_eks_cluster.eksfargate_cluster.name}"
          interactiveMode: "Never"
  EOT
}

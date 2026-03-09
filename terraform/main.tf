terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = local.common_tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── Step 1: VPC (prebuilt module) ─────────────
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  # 2 AZs — satisfies "nodes distributed across AZs" requirement
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true # one NAT saves cost; use false for HA
  enable_dns_hostnames = true # required for EKS
  enable_dns_support   = true

  # These tags are required so the ALB controller
  # and EKS can discover the subnets automatically
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  tags = local.common_tags
}

# ── Step 2: IAM Roles (custom module) ─────────
module "iam" {
  source       = "./modules/iam"
  cluster_name = var.cluster_name
  tags         = local.common_tags
}

# ── Step 3: EKS Cluster (prebuilt module) ─────
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::356142711430:user/terraform_user"

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Subnets for control plane + nodes
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # Allow kubectl access from your machine
  cluster_endpoint_public_access = true

  # EKS manages its own IAM role by default
  # but we pass ours from the iam module
  iam_role_arn    = module.iam.cluster_role_arn
  create_iam_role = false

  # ── Node Group ──────────────────────────────
  # The EKS module handles node groups internally
  eks_managed_node_groups = {
    registry_nodes = {
      node_group_name = "${var.cluster_name}-nodes"
      instance_types  = [var.node_instance_type]

      # Use the node role from our iam module
      iam_role_arn    = module.iam.node_role_arn
      create_iam_role = false

      # 2 nodes across 2 AZs (one per AZ via subnet selection)
      min_size     = 2
      max_size     = 4
      desired_size = 2

      # Place nodes in private subnets
      subnet_ids = module.vpc.private_subnets

      labels = {
        role = "worker"
      }

      tags = local.common_tags
    }
  }

  # Enable OIDC provider — needed for EBS CSI IRSA
  enable_irsa = true

  # Control plane logging
  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  tags = local.common_tags
}

# ── Step 4: Storage (custom module) ───────────
module "storage" {
  source            = "./modules/storage"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  tags              = local.common_tags

  depends_on = [module.eks, module.iam] # ← add this
}
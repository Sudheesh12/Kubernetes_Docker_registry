module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "registry-vpc-test"
  cidr     = "10.0.0.0/16"

  azs = [
    "us-east-1a",
    "us-east-1b"
  ]

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = var.cluster_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

module "ebs_irsa" {
  source = "../../modules/irsa"

  role_name     = "EBS-CSI-Role"
  oidc_provider = module.eks.oidc_provider

  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
}

module "ebs_csi" {
  source = "../../modules/ebs-csi-driver"

  cluster_name  = module.eks.cluster_name
  irsa_role_arn = module.ebs_irsa.iam_role_arn
}
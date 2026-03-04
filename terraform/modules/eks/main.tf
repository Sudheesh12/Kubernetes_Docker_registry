module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name            = var.cluster_name
  kubernetes_version = "1.29"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  enable_irsa = true
  
  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    registry_nodes = {
        instance_types = ["t3.medium"]
        desired_size = 2
        min_size = 2
        max_size = 3

        subnet_ids = var.private_subnets
    }
    
  }
  tags = var.comman_tags

}

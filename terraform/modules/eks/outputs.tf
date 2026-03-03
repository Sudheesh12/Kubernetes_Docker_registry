output "cluster_name" {
    value = module.eks.cluster_name 
}

output "cluster_endpoint" {
    value = module.eks.cluster_endpoint
}

output "oicd_provider" {
    value = module.eks.oidc_provider
}
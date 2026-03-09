output "storage_class_name" {
  description = "StorageClass name — referenced in PVC manifest"
  value       = kubernetes_storage_class.gp3.metadata[0].name
}

output "ebs_csi_role_arn" {
  description = "EBS CSI driver IAM role ARN"
  value       = aws_iam_role.ebs_csi.arn
}
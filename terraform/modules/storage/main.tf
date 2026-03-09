locals {
  ebs_csi_role_name          = "${var.cluster_name}-ebs-csi-role"
  ebs_csi_service_account    = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
  oidc_provider_url_stripped = replace(var.oidc_provider_url, "https://", "")
}

# ── EBS CSI IRSA Role ─────────────────────────
data "aws_iam_policy_document" "ebs_csi_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_stripped}:sub"
      values   = [local.ebs_csi_service_account]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = local.ebs_csi_role_name
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ── Only manage ebs-csi-driver ────────────────
# coredns, kube-proxy, vpc-cni are auto-installed by EKS
# managing them here causes timeout conflicts
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  tags                     = var.tags
}

# ── StorageClass: gp3 ─────────────────────────
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}
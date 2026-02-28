module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  cluster_log_types = []

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  endpoint_public_access  = true
  endpoint_private_access = true
  public_access_cidrs     = ["0.0.0.0/0"]

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      min_size       = 0
      max_size       = 3
      desired_size   = 0
      disk_size      = 20
      labels = {
        "node-role" = "system"
      }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  tags = local.tags
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Managed Addons
module "addon_pod_identity_agent" {
  source       = "../../modules/eks-addon"
  cluster_name = module.eks.cluster_name
  addon_name   = "eks-pod-identity-agent"
  tags         = local.tags
  depends_on   = [module.eks]
}

# VPC CNI Role
resource "aws_iam_role" "vpc_cni" {
  name = "${local.name}-vpc-cni"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

module "addon_vpc_cni" {
  source       = "../../modules/eks-addon"
  cluster_name = module.eks.cluster_name
  addon_name   = "vpc-cni"
  pod_identity_associations = [{
    service_account = "aws-node"
    role_arn        = aws_iam_role.vpc_cni.arn
  }]
  tags       = local.tags
  depends_on = [module.eks, module.addon_pod_identity_agent]
}

module "addon_coredns" {
  source       = "../../modules/eks-addon"
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
  tags         = local.tags
  depends_on   = [module.eks]
}

module "addon_kube_proxy" {
  source       = "../../modules/eks-addon"
  cluster_name = module.eks.cluster_name
  addon_name   = "kube-proxy"
  tags         = local.tags
  depends_on   = [module.eks]
}

# EBS CSI 
resource "aws_iam_role" "ebs_csi" {
  name = "${local.name}-ebs-csi"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "addon_ebs_csi" {
  source       = "../../modules/eks-addon"
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  pod_identity_associations = [{
    service_account = "ebs-csi-controller-sa"
    role_arn        = aws_iam_role.ebs_csi.arn
  }]
  tags       = local.tags
  depends_on = [module.eks, module.addon_pod_identity_agent]
}

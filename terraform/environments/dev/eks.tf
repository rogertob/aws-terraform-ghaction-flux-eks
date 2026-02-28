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

# EKS Managed Addons
module "addon_pod_identity_agent" {
  source       = "../../modules/eks-addon"
  cluster_name = module.eks.cluster_name
  addon_name   = "eks-pod-identity-agent"
  tags         = local.tags
  depends_on   = [module.eks]
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

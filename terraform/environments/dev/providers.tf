provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "eks-poc"
      Environment = "dev"
      ManagedBy   = "terraform"
      auto-delete = "no"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "flux" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
  git = {
    url    = "https://github.com/${var.github_org}/${var.github_repository}.git"
    branch = "main"
    http = {
      username = "git"
      password = var.github_token
    }
  }
}

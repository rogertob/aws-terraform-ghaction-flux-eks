module "flux" {
  source           = "../../modules/flux"
  flux_target_path = "gitops/clusters/staging"

  depends_on = [module.eks]
}

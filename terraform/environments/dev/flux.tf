module "flux" {
  source           = "../../modules/flux"
  flux_target_path = "gitops/clusters/dev"

  depends_on = [module.eks]
}

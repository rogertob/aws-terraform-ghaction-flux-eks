module "flux" {
  source           = "../../modules/flux"
  flux_target_path = "clusters/dev"

  depends_on = [module.eks]
}

module "lke-k8s" {
  source = "../../../modules/lke-k8s"

  token                   = var.token
  lke_cluster_label       = var.lke_cluster_label
  lke_cluster_region      = var.lke_cluster_region
  lke_cluster_k8s_version = var.lke_cluster_k8s_version
  pools                   = var.pools
  ipv4                      = var.ipv4
  ipv6                      = var.ipv6
  tags                    = var.tags
}

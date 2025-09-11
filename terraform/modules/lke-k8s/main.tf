//Use the Linode Provider
provider "linode" {
  token = var.token
}

//Use the linode_lke_cluster resource to create
//a Kubernetes cluster
resource "linode_lke_cluster" "main" {
  k8s_version = var.lke_cluster_k8s_version
  label       = var.lke_cluster_label
  region      = var.lke_cluster_region
  tags      = var.tags

  dynamic "pool" {
        for_each = var.pools
        content {
            type  = pool.value["type"]
            count = pool.value["count"]
        }
    }
}

module "kind-k8s" {
    source = "../../../modules/kind-k8s"
    cluster_name = var.environment
}
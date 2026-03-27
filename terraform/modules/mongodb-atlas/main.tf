resource "mongodbatlas_cluster" "cluster" {
  project_id   = var.project_id
  name         = var.cluster_name
  cluster_type = "REPLICASET"
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = var.provider_region_name
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }

  provider_name               = var.provider_name
  backing_provider_name       = var.backing_provider_name
  provider_region_name        = var.provider_region_name
  provider_instance_size_name = var.provider_instance_size_name

  mongo_db_major_version = var.mongodb_major_version
  
  # Assurez-vous d'ignorer les changements si vous prévoyez d'importer un cluster existant
  # ou si d'autres propriétés de MongoDB Atlas peuvent changer en dehors de Terraform
  lifecycle {
    ignore_changes = [
      mongo_db_major_version,
      provider_instance_size_name
    ]
  }
}

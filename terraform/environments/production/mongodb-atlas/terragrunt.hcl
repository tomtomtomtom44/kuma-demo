include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/mongodb-atlas"
}

inputs = {
  project_id                  = "66476c0f0105d871f454a2dd"
  cluster_name                = "Cluster0"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
  provider_region_name        = "EU_WEST_3"
  provider_instance_size_name = "M0"
  mongodb_major_version       = "8.0"
}

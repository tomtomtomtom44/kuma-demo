variable "project_id" {
  description = "The unique ID for the project to create the database user."
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster as it appears in Atlas."
  type        = string
  default     = "Cluster0"
}

variable "provider_name" {
  description = "Cloud provider name for the cluster (e.g., AWS, GCP, AZURE)."
  type        = string
  default     = "TENANT" # Utilisé pour le niveau gratuit ou les clusters partagés
}

variable "backing_provider_name" {
  description = "Cloud provider backing the tenant cluster."
  type        = string
  default     = "AWS"
}

variable "provider_region_name" {
  description = "Physical location of your MongoDB cluster."
  type        = string
  default     = "US_EAST_1"
}

variable "provider_instance_size_name" {
  description = "Atlas cluster tier."
  type        = string
  default     = "M0"
}

variable "mongodb_major_version" {
  description = "Version de MongoDB."
  type        = string
  default     = "8.0"
}

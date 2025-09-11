variable "token" {
  description = "Your Linode API Personal Access Token. (required)"
}

variable "lke_cluster_k8s_version" {
  description = "The Kubernetes version for the LKE cluster."
  type        = string
}

variable "lke_cluster_label" {
  description = "The label for the LKE cluster."
  type        = string
}

variable "lke_cluster_region" {
  description = "The region for the LKE cluster."
  type        = string
}

variable "tags" {
  description = "Tags to apply to your cluster for organizational purposes. (optional)"
  type = list(string)
  default = ["testing"]
}

variable "pools" {
  description = "The Node Pool specifications for the Kubernetes cluster. (required)"
  type = list(object({
    type = string
    count = number
  }))
  default = [
    {
      type = "g6-nanode-1"
      count = 2
    }
  ]
}

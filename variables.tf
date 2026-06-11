variable "region" {
  description = "AWS region for the cluster."
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "upgrade-demo"
}

# This is the line you change to upgrade the cluster.
# Bump it one minor version at a time (for example 1.32 -> 1.33),
# open a pull request, and review the plan before merging.
variable "kubernetes_version" {
  description = "Kubernetes (EKS) version. Change this to upgrade the cluster."
  type        = string
  default     = "1.32"
}

variable "vpc_id" {
  description = "VPC the cluster runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the cluster and node groups (private subnets recommended)."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_min_size" {
  description = "Minimum node count."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum node count."
  type        = number
  default     = 5
}

variable "node_desired_size" {
  description = "Desired node count."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "eks-upgrade-demo"
    ManagedBy = "Terraform"
  }
}

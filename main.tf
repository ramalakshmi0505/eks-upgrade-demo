provider "aws" {
  region = var.region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name = var.cluster_name

  # The whole point of this repo: the cluster version is one variable.
  # An upgrade is a one-line change, reviewed as a pull request.
  kubernetes_version = var.kubernetes_version

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  # Add-ons are managed by EKS and upgraded alongside the cluster.
  # Leaving the version unset lets EKS pick the default compatible with
  # the kubernetes_version above, so they move together on an upgrade.
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Managed node groups follow the cluster version. After the control
  # plane upgrade, the same apply rolls the nodes to match.
  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
    }
  }

  tags = var.tags
}

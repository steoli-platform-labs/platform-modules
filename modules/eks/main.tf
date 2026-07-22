module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                                     = var.name
  kubernetes_version                       = var.kubernetes_version
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    for arn in var.cluster_admin_principal_arns : arn => {
      principal_arn = arn

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa = true

  eks_managed_node_groups = {
    system = {
      instance_types = var.node_instance_types
      min_size       = 2
      desired_size   = 2
      max_size       = 4
      labels = {
        workload = "system"
      }
    }
  }

  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  tags = var.tags
}

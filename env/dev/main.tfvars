aws_region = "ap-south-1"
common_vars = {
  environment  = "dev"
  project_name = "eks"
  common_tags = {
    "Project"     = "EKS-Cluster"
    "Environment" = "Dev"
    "ManagedBy"   = "Terraform"
    "Owner"       = "Sivaramakrishna"
  }
}

vpc = {
  vpc_cidr            = "172.17.0.0/16"
  azs                 = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidr  = ["172.17.0.0/20", "172.17.16.0/20"]
  private_subnet_cidr = ["172.17.32.0/20", "172.17.48.0/20"]
  db_subnet_cidr      = ["172.17.64.0/20", "172.17.80.0/20"]
  enable_nat          = false
}

sg = {
  control_plane_sg_name        = "control-plane-sg"
  control_plane_sg_description = "Security group for the control plane"
  node_group_sg_name           = "node-group-sg"
  node_group_sg_description    = "Security group for the node group"
  bastion_sg_name              = "bastion-sg"
  bastion_sg_description       = "Security group for the bastion host"
  alb_sg_name                  = "alb-sg"
  alb_sg_description           = "Security group for the Application Load Balancer"
}

eks = {
  bootstrap_cluster_creator_admin_permissions = true
  eks_version                                 = "1.32"
  endpoint_private_access                     = true
  endpoint_public_access                      = true
  public_access_cidrs                         = ["0.0.0.0/0"]
  node_groups = {
    ugl = {
      instance_type = ["t3a.medium"]
      capacity_type = "ON_DEMAND"
      desired_size  = 6
      max_size      = 6
      min_size      = 1
    }
  }

  addons = {
    vpc-cni = "v1.19.6-eksbuild.7"
    metrics-server = "v0.8.0-eksbuild.1"
    eks-pod-identity-agent = "v1.3.8-eksbuild.2"
    aws-ebs-csi-driver = "v1.45.0-eksbuild.2"
    external-dns = "v0.18.0-eksbuild.1"
  }

  eks_iam_access = {
    admin = {
      principal_arn     = "arn:aws:iam::522814728660:root"
      policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      kubernetes_groups = []
      access_scope_type = "cluster" 
    }
  }

}



# Pod Identities
ebs_pod_identity = {
  service_account = "ebs-csi-controller-sa"
  namespace = "kube-system"
}
alb_pod_identity = {
  service_account = "aws-load-balancer-controller"
  namespace = "kube-system"
}

alb_pod_identity = {
  service_account = "aws-load-balancer-controller"
  namespace = "kube-system"
}

external_dns_pod_identity = {
  service_account = "external-dns"
  namespace = "external-dns"
}

storage_class_names = ["instana","expense","logging"]
namespace_names = ["expense","logging"]
module "eks-vpc" {
  source              = "../modules/vpc"
  environment         = var.common_vars["environment"]
  project             = var.common_vars["project_name"]
  common_tags         = var.common_vars["common_tags"]
  vpc_cidr            = var.vpc["vpc_cidr"]
  public_subnet_cidr  = var.vpc["public_subnet_cidr"]
  azs                 = var.vpc["azs"]
  private_subnet_cidr = var.vpc["private_subnet_cidr"]
  db_subnet_cidr      = var.vpc["db_subnet_cidr"]
  enable_nat          = var.vpc["enable_nat"]
}
module "eks_cluster" {
  source = "../modules/eks"

  environment = var.common_vars["environment"]
  project     = var.common_vars["project_name"]
  common_tags = var.common_vars["common_tags"]

  bootstrap_cluster_creator_admin_permissions = var.eks["bootstrap_cluster_creator_admin_permissions"]
  eks_version                                 = var.eks["eks_version"]
  subnet_ids                                  = module.eks-vpc.private_subnet_ids
  security_group_ids                          = [module.control_plane.sg_id]
  endpoint_private_access                     = var.eks["endpoint_private_access"]
  endpoint_public_access                      = var.eks["endpoint_public_access"]
  public_access_cidrs                         = var.eks["public_access_cidrs"]
  node_groups                                 = var.eks["node_groups"]
  node_group_security_group_ids               = [module.node_group.sg_id]
  node_subnet_ids                             = module.eks-vpc.private_subnet_ids
  addons                                      = var.eks["addons"]
  eks_iam_access                              = var.eks["eks_iam_access"]
}
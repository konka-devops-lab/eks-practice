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
  subnet_ids                                  = module.eks-vpc.public_subnet_ids
  security_group_ids                          = [module.control_plane.sg_id]
  endpoint_private_access                     = var.eks["endpoint_private_access"]
  endpoint_public_access                      = var.eks["endpoint_public_access"]
  public_access_cidrs                         = var.eks["public_access_cidrs"]
  node_groups                                 = var.eks["node_groups"]
  node_group_security_group_ids               = [module.node_group.sg_id]
  node_subnet_ids                             = module.eks-vpc.public_subnet_ids
  addons                                      = var.eks["addons"]
  eks_iam_access                              = var.eks["eks_iam_access"]
}

module "ebs_pod_identity" {
  source                 = "../modules/pod-identities"
  cluster_name           = module.eks_cluster.name
  environment            = var.common_vars["environment"]
  project_name           = var.common_vars["project_name"]
  policy                 = "${path.module}/../env/${var.common_vars["environment"]}/policies/ebs_csi_policy.json"
  namespace              = var.ebs_pod_identity["namespace"]
  service_account        = var.ebs_pod_identity["service_account"]
  pod_identity_role_name = var.ebs_pod_identity["service_account"]
}

module "alb_ingress_pod_identity" {
  source                 = "../modules/pod-identities"
  cluster_name           = module.eks_cluster.name
  environment            = var.common_vars["environment"]
  project_name           = var.common_vars["project_name"]
  policy                 = "${path.module}/../env/${var.common_vars["environment"]}/policies/alb_ingress_policy.json"
  namespace              = var.alb_pod_identity["namespace"]
  service_account        = var.alb_pod_identity["service_account"]
  pod_identity_role_name = var.alb_pod_identity["service_account"]
}

module "external_dns_pod_identity" {
  source                 = "../modules/pod-identities"
  cluster_name           = module.eks_cluster.name
  environment            = var.common_vars["environment"]
  project_name           = var.common_vars["project_name"]
  policy                 = "${path.module}/../env/${var.common_vars["environment"]}/policies/external_dns_policy.json"
  namespace              = var.external_dns_pod_identity["namespace"]
  service_account        = var.external_dns_pod_identity["service_account"]
  pod_identity_role_name = var.external_dns_pod_identity["service_account"]
}

# module "loki_pod_identity" {
#   source                 = "../modules/pod-identities"
#   cluster_name           = module.eks_cluster.name
#   environment            = var.common_vars["environment"]
#   project_name           = var.common_vars["project_name"]
#   policy                 = "${path.module}/../env/${var.common_vars["environment"]}/policies/loki_s3_policy.json"
#   namespace              = var.loki_pod_identity["namespace"]
#   service_account        = var.loki_pod_identity["service_account"]
#   pod_identity_role_name = var.loki_pod_identity["service_account"]
# }

# module "admin_user" {
#   depends_on                     = [module.eks]
#   source                         = "../modules/ec2"
#   environment                    = var.common_vars["environment"]
#   project_name                   = var.common_vars["project_name"]
#   common_tags                    = var.common_vars["common_tags"]
#   ami                            = data.aws_ami.amazon_linux.id
#   instance_type                  = var.admin_instance["instance_type"]
#   key_name                       = var.admin_instance["key_name"]
#   security_groups                = [module.bastion.sg_id]
#   monitoring                     = var.admin_instance["monitoring"]
#   subnet_id                      = module.eks_vpc.public_subnet_ids[0]
#   user_data                      = var.admin_instance["user_data"]
#   use_null_resource_for_userdata = var.admin_instance["use_null_resource_for_userdata"]
#   remote_exec_user               = var.admin_instance["remote_exec_user"]
#   private_key                    = data.aws_ssm_parameter.ec2_key.value
#   iam_instance_profile           = var.admin_instance["iam_instance_profile"]
# }

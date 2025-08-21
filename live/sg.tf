module "control_plane" {
  source         = "../modules/sg"
  environment    = var.common_vars["environment"]
  project        = var.common_vars["project_name"]
  common_tags    = var.common_vars["common_tags"]
  vpc_id         = module.eks_vpc.vpc_id
  sg_name        = var.sg["control_plane_sg_name"]
  sg_description = var.sg["control_plane_sg_description"]
}
module "node_group" {
  source                         = "../modules/sg"
  environment                    = var.common_vars["environment"]
  project                        = var.common_vars["project_name"]
  common_tags                    = var.common_vars["common_tags"]
  vpc_id                         = module.eks_vpc.vpc_id
  sg_name                        = var.sg["node_group_sg_name"]
  sg_description                 = var.sg["node_group_sg_description"]
  enable_karpenter_discovery_tag = var.sg["enable_karpenter_discovery_tag"]
  karpenter_cluster_name         = module.eks_cluster.name
}
module "bastion" {
  source         = "../modules/sg"
  environment    = var.common_vars["environment"]
  project        = var.common_vars["project_name"]
  common_tags    = var.common_vars["common_tags"]
  vpc_id         = module.eks_vpc.vpc_id
  sg_name        = var.sg["bastion_sg_name"]
  sg_description = var.sg["bastion_sg_description"]
}
module "alb" {
  source         = "../modules/sg"
  environment    = var.common_vars["environment"]
  project        = var.common_vars["project_name"]
  common_tags    = var.common_vars["common_tags"]
  vpc_id         = module.eks_vpc.vpc_id
  sg_name        = var.sg["alb_sg_name"]
  sg_description = var.sg["alb_sg_description"]
}

resource "aws_security_group_rule" "internet_controlplane" {
  description       = "Allow HTTPS inbound traffic from the internet to the control plane"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.control_plane.sg_id
}

resource "aws_security_group_rule" "controlplane_nodegroup" {
  description              = "Allow traffic from control plane to node group"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = module.control_plane.sg_id
  security_group_id        = module.node_group.sg_id
}
resource "aws_security_group_rule" "nodegroup_controlplane" {
  description              = "Allow traffic from node group to control plane"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = module.node_group.sg_id
  security_group_id        = module.control_plane.sg_id
}

resource "aws_security_group_rule" "nodegroup_itself" {
  description       = "Allow traffic from node group to itself"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [var.vpc["vpc_cidr"]]
  security_group_id = module.node_group.sg_id
}
resource "aws_security_group_rule" "alb_nodegroup" {
  description              = "Allow traffic from ALB to node group"
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = module.alb.sg_id
  security_group_id        = module.node_group.sg_id
}
resource "aws_security_group_rule" "bastion_nodegroup" {
  description              = "Allow traffic from bastion to node group"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id        = module.node_group.sg_id
}

resource "aws_security_group_rule" "http_alb" {
  description       = "Allow HTTP traffic from Internet to ALB"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.alb.sg_id
}

resource "aws_security_group_rule" "https_alb" {
  description       = "Allow HTTPs traffic from Internet to ALB"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.alb.sg_id
}

resource "aws_security_group_rule" "ssh_bastion" {
  description       = "Allow SSH traffic from Internet to Bastion host"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}
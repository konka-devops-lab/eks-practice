# Common Variables for EKS Module
variable "environment" {
  description = "The environment for the VPC (e.g., dev, staging, prod)"
  type        = string
}
variable "project" {
  description = "The project name for the VPC"
  type        = string
}
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# Variables for EKS Cluster
variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Enable admin permissions for the bootstrap cluster creator"
  type        = bool
}
variable "eks_version" {
  description = "The version of the EKS cluster"
  type        = string
}
variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}
variable "security_group_ids" {
  description = "List of security group IDs for the EKS cluster"
  type        = list(string)
}
variable "endpoint_private_access" {
    description = "Enable private access to the EKS API endpoint"
    type        = bool 
}
variable "endpoint_public_access" {
    description = "Enable public access to the EKS API endpoint"
    type        = bool 
}
variable "public_access_cidrs" {
    description = "List of CIDRs allowed to access the EKS API endpoint"
    type        = list(string)
}

# Launch Template Variables

variable "node_groups" {}
variable "node_group_security_group_ids" {}
variable "node_subnet_ids" {}
variable "addons" {}
variable "eks_iam_access" {}
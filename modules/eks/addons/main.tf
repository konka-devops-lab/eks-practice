resource "aws_eks_addon" "example" {
  cluster_name                = var.cluster_name
  addon_name                  = var.addon_name
  addon_version               = var.addon_version
  resolve_conflicts_on_create = "OVERWRITE"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}
variable "addon_name" {
  description = "The name of the EKS addon"
  type        = string
}
variable "addon_version" {
  description = "The version of the EKS addon"
  type        = string
}

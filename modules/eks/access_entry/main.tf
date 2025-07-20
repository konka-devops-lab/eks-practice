resource "aws_eks_access_entry" "this" {
  cluster_name  = var.cluster_name
  principal_arn = var.principal_arn
  kubernetes_groups = var.kubernetes_groups
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  cluster_name  = var.cluster_name
  policy_arn    = var.policy_arn
  principal_arn = var.principal_arn

  access_scope {
    type = var.access_scope_type

    # Only set namespaces if type is "namespace"
    namespaces = var.access_scope_type == "namespace" ? var.namespaces : null
  }
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "principal_arn" {
  description = "IAM Role or User ARN"
  type        = string
}

variable "policy_arn" {
  description = "EKS Access Policy ARN"
  type        = string
}

variable "access_scope_type" {
  description = "Access scope type: cluster or namespace"
  type        = string
  validation {
    condition     = contains(["cluster", "namespace"], var.access_scope_type)
    error_message = "access_scope_type must be either 'cluster' or 'namespace'."
  }
}
variable "namespaces" {
  description = "List of namespaces (only required for namespace scope)"
  type        = list(string)
  default     = []
}
variable "kubernetes_groups" {
  description = "List of Kubernetes groups to associate with the IAM principal"
  type        = list(string)
  default     = []
}
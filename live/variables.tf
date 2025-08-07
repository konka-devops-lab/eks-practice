variable "aws_region" {}
variable "common_vars" {}
variable "vpc" {}
variable "sg" {}
variable "eks" {}
variable "ebs_pod_identity" {}
variable "alb_pod_identity" {}
variable "external_dns_pod_identity" {}
# variable "loki_pod_identity" {}

variable "karpenter_version" {
  type        = string
  description = "Version of Karpenter Helm chart"
}

variable "storage_class_names" {
  type = list(string)
}

variable "namespace_names" {
  type = list(string)
}
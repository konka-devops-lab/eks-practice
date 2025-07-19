output "vpc_id" {
  description = "The ID of the VPC where the EKS cluster is deployed"
  value       = module.eks-vpc.vpc_id
}
output "public_subnet_ids" {
  description = "List of public subnet IDs in the VPC"
  value       = module.eks-vpc.public_subnet_ids
}
output "private_subnet_ids" {
  description = "List of private subnet IDs in the VPC"
  value       = module.eks-vpc.private_subnet_ids
}
output "db_subnet_ids" {
  description = "List of database subnet IDs in the VPC"
  value       = module.eks-vpc.db_subnet_ids
}
output "db_subnet_group_name" {
  description = "The name of the database subnet group"
  value       = module.eks-vpc.db_subnet_group_name
}
# output "cluster_name" {
#   description = "The name of the EKS cluster"
#   value       = module.eks_cluster.cluster_name
# }
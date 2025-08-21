output "vpc_id" {
  description = "The ID of the VPC where the EKS cluster is deployed"
  value       = module.eks_vpc.vpc_id
}
output "public_subnet_ids" {
  description = "List of public subnet IDs in the VPC"
  value       = module.eks_vpc.public_subnet_ids
}
output "private_subnet_ids" {
  description = "List of private subnet IDs in the VPC"
  value       = module.eks_vpc.private_subnet_ids
}
output "db_subnet_ids" {
  description = "List of database subnet IDs in the VPC"
  value       = module.eks_vpc.db_subnet_ids
}
output "db_subnet_group_name" {
  description = "The name of the database subnet group"
  value       = module.eks_vpc.db_subnet_group_name
}
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_cluster.name
}

# output "admin_public_ip" {
#   value = module.admin_user.public_ip
# }
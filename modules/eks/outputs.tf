output "name" {
    description = "The name of the EKS cluster"
    value       = aws_eks_cluster.example.id
}
output "endpoint" {
    description = "The endpoint of the EKS cluster"
    value       = aws_eks_cluster.example.endpoint
}
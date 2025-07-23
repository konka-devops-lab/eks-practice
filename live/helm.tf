resource "null_resource" "kube-config" {
  depends_on = [module.eks_cluster]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_cluster.name} --region ${var.aws_region}"
  }
}

# resource "helm_release" "aws_lb_controller" {
#   depends_on = [module.eks_cluster, null_resource.kube-config]
#   name       = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"

#   set {
#     name  = "clusterName"
#     value = module.eks_cluster.name
#   }

#   # set {
#   #   name  = "serviceAccount.create"
#   #   value = "false"
#   # }

#   set {
#     name  = "region"
#     value = var.aws_region
#   }

#   set {
#     name  = "vpcId"
#     value = module.eks-vpc.vpc_id
#   }
# }

resource "helm_release" "aws_lb_controller" {
  depends_on = [module.eks_cluster, null_resource.kube-config]
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set = [
    {
      name  = "clusterName"
      value = module.eks_cluster.name
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = module.eks-vpc.vpc_id
    }
  ]
}

resource "null_resource" "kube-config" {
  depends_on = [module.eks_cluster]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_cluster.name} --region ${var.aws_region}"
  }
}

resource "helm_release" "aws_lb_controller" {
  depends_on       = [module.eks_cluster, null_resource.kube-config]
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  create_namespace = false

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
      value = module.eks_vpc.vpc_id
    }
  ]
}

resource "helm_release" "istio-base" {
  depends_on       = [module.eks_cluster, null_resource.kube-config]
  name             = "istio-base"
  namespace        = "istio-system"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  create_namespace = true
  wait             = true
}

resource "helm_release" "istiod" {
  depends_on = [module.eks_cluster, null_resource.kube-config]
  name       = "istiod"
  namespace  = "istio-system"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  wait       = true
}

# resource "kubernetes_namespace" "ns" {
#   metadata {
#     name = "instana"

#     labels = {
#       istio-injection = "enabled"
#     }
#   }
#   depends_on       = [module.eks_cluster, null_resource.kube-config]
# }
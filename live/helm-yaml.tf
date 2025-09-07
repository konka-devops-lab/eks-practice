######################################## Null Resource to Update Kubeconfig ########################################
resource "null_resource" "kube-config" {
  depends_on = [module.eks_cluster]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_cluster.name} --region ${var.aws_region}"
  }
}

# ######################################## ALB Ingress Helm Chart ##############################################################
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
######################################### Istio Helm Charts ##############################################################
# resource "helm_release" "istio-base" {
#   depends_on       = [module.eks_cluster, null_resource.kube-config]
#   name             = "istio-base"
#   namespace        = "istio-system"
#   repository       = "https://istio-release.storage.googleapis.com/charts"
#   chart            = "base"
#   create_namespace = true
#   wait             = true
# }

# resource "helm_release" "istiod" {
#   depends_on = [helm_release.istio-base]
#   name       = "istiod"
#   namespace  = "istio-system"
#   repository = "https://istio-release.storage.googleapis.com/charts"
#   chart      = "istiod"
#   wait       = true
# }
# resource "helm_release" "istio-ingress" {
#   depends_on = [helm_release.istiod]
#   name       = "istio-ingressgateway"
#   namespace  = "istio-system"
#   repository = "https://istio-release.storage.googleapis.com/charts"
#   chart      = "gateway"
#   values = [
#     <<EOT
# service:
#   type: ClusterIP
# EOT
#   ]
# }
# resource "helm_release" "istio-egress" {
#   depends_on = [helm_release.istiod]
#   name       = "istio-egressgateway"
#   namespace  = "istio-system"
#   repository = "https://istio-release.storage.googleapis.com/charts"
#   chart      = "gateway"
#   values = [
#     <<EOT
# service:
#   type: ClusterIP
# EOT
#   ]
# }

# ######################################### Karpenter Helm Chart ##############################################################

# resource "helm_release" "karpenter" {
#   namespace  = "kube-system"
#   name       = "karpenter"
#   repository = "oci://public.ecr.aws/karpenter"
#   chart      = "karpenter"
#   version    = "1.6.0"
#   wait       = false

#   values = [
#     <<-EOT
#     serviceAccount:
#       name: ${module.karpenter.service_account}
#     settings:
#       clusterName: ${module.eks_cluster.name}
#       clusterEndpoint: ${module.eks_cluster.endpoint}
#       interruptionQueue: ${module.karpenter.queue_name}
#     EOT
#   ]
#   depends_on = [module.eks_cluster]
# }
# ############################################# Kube Prometheus Stack ##########################################################
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "oci://ghcr.io/prometheus-community/charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "76.5.1"
  depends_on       = [module.eks_cluster]
}
############################################# EC2NoodeClass & NodePool #######################################################
# resource "kubernetes_manifest" "karpenter_ec2_nodeclass" {
#   manifest = {
#     apiVersion = "karpenter.k8s.aws/v1"
#     kind       = "EC2NodeClass"
#     metadata = {
#       name = "${module.eks_cluster.name}-nc"
#     }
#     spec = {
#       amiSelectorTerms = [{
#         alias = "al2023@latest"
#       }]
#       subnetSelectorTerms = [{
#         tags = {
#           "karpenter.sh/discovery" = module.eks_cluster.name
#         }
#       }]
#       securityGroupSelectorTerms = [{
#         tags = {
#           "karpenter.sh/discovery" = module.eks_cluster.name
#         }
#       }]
#       role = module.karpenter.node_iam_role_name # Changed from instanceProfile to role
#       tags = {
#         "Name" = "${module.eks_cluster.name}-karpenter-worker"
#       }
#     }
#   }
#   lifecycle {
#     prevent_destroy = true
#   }
#   depends_on = [helm_release.karpenter, null_resource.kube-config]
# }

# resource "kubernetes_manifest" "karpenter_node_pool" {
#   manifest = {
#     apiVersion = "karpenter.sh/v1"
#     kind       = "NodePool"
#     metadata = {
#       name = "${module.eks_cluster.name}-nodepool"
#     }
#     spec = {
#       template = {
#         spec = {
#           nodeClassRef = {
#             name  = kubernetes_manifest.karpenter_ec2_nodeclass.manifest["metadata"]["name"]
#             kind  = "EC2NodeClass"
#             group = "karpenter.k8s.aws"
#           }
#           requirements = [
#             {
#               key      = "kubernetes.io/arch"
#               operator = "In"
#               values   = ["amd64"]
#             },
#             {
#               key      = "kubernetes.io/os"
#               operator = "In"
#               values   = ["linux"]
#             },
#             {
#               key      = "karpenter.sh/capacity-type"
#               operator = "In"
#               values   = ["spot", "on-demand"]
#             },
#             {
#               key      = "node.kubernetes.io/instance-type"
#               operator = "In"
#               values   = ["t3a.small", "t3a.medium", "t3a.large"]
#             }
#           ]
#         }
#       }
#       limits = {
#         cpu    = "1000"
#         memory = "1000Gi"
#       }
#       disruption = {
#         consolidationPolicy = "WhenEmpty"
#         consolidateAfter    = "30s"
#       }
#     }
#   }

#   lifecycle {
#     prevent_destroy = true
#   }

#   depends_on = [helm_release.karpenter, null_resource.kube-config]
# }


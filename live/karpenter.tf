module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks_cluster.name
  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  depends_on = [module.eks_cluster]
}
resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.6.0"
  wait       = false

  values = [
    <<-EOT
    serviceAccount:
      name: ${module.karpenter.service_account}
    settings:
      clusterName: ${module.eks_cluster.name}
      clusterEndpoint: ${module.eks_cluster.endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]
  depends_on = [module.eks_cluster]
}


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
#               values   = ["t3a.small", "t3a.medium", "t3a.large", "t3a.xlarge"]
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

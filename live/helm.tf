resource "null_resource" "kube-config" {
  depends_on = [module.eks_cluster]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_cluster.name} --region ${var.aws_region}"
  }
}

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

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = "kube-system"
  create_namespace = true

  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  set = [
    {
      name  = "settings.clusterName"
      value = module.eks_cluster.name
    },
    {
      name  = "settings.interruptionQueue"
      value = module.eks_cluster.name
    },
    {
      name  = "controller.resources.requests.cpu"
      value = "1"
    },
    {
      name  = "controller.resources.requests.memory"
      value = "1Gi"
    },
    {
      name  = "controller.resources.limits.cpu"
      value = "1"
    },
    {
      name  = "controller.resources.limits.memory"
      value = "1Gi"
    }
  ]
  timeout = 600
  wait    = true
}


resource "kubernetes_namespace" "example" {
  depends_on = [module.eks_cluster, null_resource.kube-config]
  for_each   = toset(var.namespace_names)
  metadata {
    name = each.key
  }
  provisioner "local-exec" {
    command = <<EOT
  aws eks update-kubeconfig --name dev-eks --region ap-south-1
  until kubectl get ns; do echo "Waiting for cluster DNS..."; sleep 5; done
  EOT
  }
}

resource "kubernetes_storage_class" "example" {
  depends_on = [module.eks_cluster, null_resource.kube-config]
  for_each   = toset(var.storage_class_names)
  metadata {
    name = each.key
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true

  parameters = {
    type                        = "gp3"
    encrypted                   = "true"
    "csi.storage.k8s.io/fstype" = "xfs"
  }

  provisioner "local-exec" {
    command = <<EOT
  aws eks update-kubeconfig --name dev-eks --region ap-south-1
  until kubectl get ns; do echo "Waiting for cluster DNS..."; sleep 5; done
  EOT
  }

  volume_binding_mode = "WaitForFirstConsumer"
}



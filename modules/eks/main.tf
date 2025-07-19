locals {
  name = "${var.environment}-${var.project}"
}

# EKS Cluster
resource "aws_eks_cluster" "example" {
  name = local.name

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  role_arn = aws_iam_role.cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = var.security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs = var.public_access_cidrs
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

  tags = merge(
    {
      Name = local.name
    },
    var.common_tags
  )
}

resource "aws_iam_role" "cluster" {
  name = "${local.name}-cluster-example"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
  tags = merge(
    {
      Name = "${local.name}-cluster-example"
    },
    var.common_tags
  )
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# NodeGroup IAM Role
resource "aws_iam_role" "node" {
  name = "${local.name}-cluster-worker-node"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = merge(
    {
      Name = "${local.name}-cluster-worker-node"
    },
    var.common_tags
  )
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# Launch Template
resource "aws_launch_template" "node" {
  for_each = var.node_groups
  name = "${local.name}-nodegroup-launch-template"

  vpc_security_group_ids = var.node_group_security_group_ids

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }
  key_name = "siva"

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name = "${local.name}-ng-${each.key}"
      }
    )
  }
}
# NodeGroup
resource "aws_eks_node_group" "example" {
  for_each = var.node_groups
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  capacity_type = each.value["capacity_type"]
  instance_types = each.value["instance_type"]
  scaling_config {
    desired_size = each.value["desired_size"]
    max_size     = each.value["max_size"]
    min_size     = each.value["min_size"]
  }

  launch_template {
    id      = aws_launch_template.node[each.key].id
    version = "$Latest"
  }

  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}

module addons {
  depends_on = [ aws_eks_node_group.example ]
  source = "./addons"
  for_each = var.addons
  cluster_name  = aws_eks_cluster.example.name
  addon_name = each.key
  addon_version = each.value
}
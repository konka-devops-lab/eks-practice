data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}
locals {
  # IAM Role Name: formatted as TitleCase without dashes
  name = "${title(replace(var.environment, "-", ""))}${title(replace(var.project_name, "-", ""))}${title(replace(var.pod_identity_role_name, "-", ""))}"
}

resource "aws_iam_role" "example" {
  name = local.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "test_policy" {
  name = local.name
  role = aws_iam_role.example.id
  policy = file(var.policy)
}


resource "aws_eks_pod_identity_association" "example" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account
  role_arn        = aws_iam_role.example.arn
}
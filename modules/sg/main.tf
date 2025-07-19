locals {
  name = "${var.environment}-${var.project}-${var.sg_name}"
}
resource "aws_security_group" "asg" {
  name        = local.name
  description = var.sg_description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = each.value.from_port
      to_port     = each.value.to_port
      protocol    = each.value.protocol
      cidr_blocks = each.value.cidr_blocks
      description = each.value.description
    }
  }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }

  tags = merge({
    Name = local.name
  },
  var.common_tags
  )
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# NLB
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
locals {
  access_logs_enabled = var.enable_access_logs && trimspace(var.access_logs_bucket) != ""
  nlb_scope           = var.internal ? "internal" : "external"

  create_tls_listener = var.listener_protocol == "TLS"
  create_tcp_listener = var.listener_protocol == "TCP"
}

resource "aws_lb" "this" {
  name                             = "${var.prefix}-${var.stack_name}"
  load_balancer_type               = "network"
  internal                         = var.internal
  subnets                          = sort(var.subnet_ids)
  security_groups                  = var.security_group_ids
  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  dynamic "access_logs" {
    for_each = local.access_logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "nlb/${local.nlb_scope}/${var.stack_name}"
      enabled = true
    }
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-${var.stack_name}" })
}

resource "aws_lb_target_group" "main" {
  name        = substr(replace("${var.prefix}-${var.stack_name}", "_", "-"), 0, 32)
  port        = var.target_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  deregistration_delay = var.deregistration_delay

  health_check {
    protocol = var.health_check_protocol
    port     = var.health_check_port
    path     = contains(["HTTP", "HTTPS"], var.health_check_protocol) ? var.health_check_path : null
  }

  dynamic "stickiness" {
    for_each = var.target_type == "instance" ? [1] : []
    content {
      enabled = true
      type    = "source_ip"
    }
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-${var.stack_name}" })
}

resource "aws_lb_listener" "main_tls" {
  count = local.create_tls_listener ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "TLS"

  ssl_policy      = var.ssl_policy
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_listener" "main_tcp" {
  count = local.create_tcp_listener ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group_attachment" "instance_targets" {
  count = var.target_type == "instance" ? length(var.instance_ids) : 0

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.instance_ids[count.index]
  port             = var.target_port
}

resource "aws_lb_target_group_attachment" "alb_target" {
  count = var.target_type == "alb" ? 1 : 0

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.alb_arn
  port             = var.target_port
}

resource "aws_lb_target_group" "ssh" {
  count = var.create_ssh_listener ? 1 : 0

  name        = substr(replace("${var.prefix}-${var.stack_name}-ssh", "_", "-"), 0, 32)
  port        = 22
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  deregistration_delay = var.deregistration_delay

  health_check {
    protocol = "TCP"
    port     = var.health_check_port
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-${var.stack_name}-ssh" })
}

resource "aws_lb_listener" "ssh" {
  count = var.create_ssh_listener ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssh[0].arn
  }
}

resource "aws_lb_target_group_attachment" "ssh" {
  count = var.create_ssh_listener ? length(var.ssh_instance_ids) : 0

  target_group_arn = aws_lb_target_group.ssh[0].arn
  target_id        = var.ssh_instance_ids[count.index]
  port             = 22
}

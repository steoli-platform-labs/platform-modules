# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ALB
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
locals {
  https_enabled = trimspace(var.certificate_arn) != ""
}

# Internal ALB
resource "aws_lb" "internal" {
  count              = var.create_internal_alb ? 1 : 0
  name               = "${var.prefix}-int"
  load_balancer_type = "application"
  internal           = true
  subnets            = sort(var.private_subnet_ids)
  security_groups    = [var.alb_security_group_id]

  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.enable_access_logs && trimspace(var.access_logs_bucket) != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "alb/internal"
      enabled = true
    }
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-int" })
}

resource "aws_lb_listener" "internal_http" {
  count             = var.create_internal_alb ? 1 : 0
  load_balancer_arn = aws_lb.internal[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.https_enabled ? "redirect" : "fixed-response"

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "fixed_response" {
      for_each = local.https_enabled ? [] : [1]
      content {
        content_type = "text/plain"
        status_code  = "503"
        message_body = "Internal HTTPS not configured"
      }
    }
  }
}

resource "aws_lb_listener" "internal_https" {
  count             = var.create_internal_alb && local.https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.internal[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "503"
      message_body = "No internal rule configured"
    }
  }
}

resource "aws_lb_listener_certificate" "internal_extra" {
  for_each = (
    var.create_internal_alb && local.https_enabled
  ) ? toset(var.additional_certificate_arns) : toset([])

  listener_arn    = aws_lb_listener.internal_https[0].arn
  certificate_arn = each.value
}

# External ALB
resource "aws_lb" "external" {
  count              = var.create_external_alb ? 1 : 0
  name               = "${var.prefix}-ext"
  load_balancer_type = "application"
  internal           = false
  subnets            = sort(var.public_subnet_ids)
  security_groups    = [var.alb_security_group_id]

  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.enable_access_logs && trimspace(var.access_logs_bucket) != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "alb/external"
      enabled = true
    }
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-ext" })
}

resource "aws_lb_listener" "external_http" {
  count             = var.create_external_alb ? 1 : 0
  load_balancer_arn = aws_lb.external[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.https_enabled ? "redirect" : "fixed-response"

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "fixed_response" {
      for_each = local.https_enabled ? [] : [1]
      content {
        content_type = "text/plain"
        status_code  = "503"
        message_body = "External HTTPS not configured"
      }
    }
  }
}

resource "aws_lb_listener" "external_https" {
  count             = var.create_external_alb && local.https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.external[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "503"
      message_body = "No external rule configured"
    }
  }
}

resource "aws_lb_listener_certificate" "external_extra" {
  for_each = (
    var.create_external_alb && local.https_enabled
  ) ? toset(var.additional_certificate_arns) : toset([])

  listener_arn    = aws_lb_listener.external_https[0].arn
  certificate_arn = each.value
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ALB
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
locals {
  use_fixed_response = var.fixed_response != null
  use_redirect       = var.redirect != null

  requires_target_group = !local.use_fixed_response && !local.use_redirect

}

# Only create target group for normal forward rules
resource "aws_lb_target_group" "this" {
  count = local.requires_target_group ? 1 : 0

  # TG names are limited to 32 chars, must be unique per region/account.
  name        = substr(replace("${var.prefix}-${var.stack_name}", "_", "-"), 0, 32)
  port        = var.backend_port
  protocol    = var.backend_protocol
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = var.health_check_protocol
    matcher             = var.health_check_matcher
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
  }

  deregistration_delay = var.deregistration_delay

  tags = merge(var.common_tags, { Name = "${var.prefix}-${var.stack_name}" })
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.listener_arn
  priority     = var.priority

  dynamic "action" {
    for_each = local.use_fixed_response ? [1] : []
    content {
      type = "fixed-response"

      fixed_response {
        content_type = var.fixed_response.content_type
        message_body = var.fixed_response.message_body
        status_code  = var.fixed_response.status_code
      }
    }
  }
  dynamic "action" {
    for_each = local.use_redirect ? [1] : []
    #for_each = var.redirect != null ? [var.redirect] : []
    content {
      type = "redirect"

      redirect {
        host        = var.redirect.host
        port        = var.redirect.port
        protocol    = var.redirect.protocol
        path        = var.redirect.path
        query       = var.redirect.query
        status_code = var.redirect.status_code
      }
    }
  }

  dynamic "action" {
    for_each = local.requires_target_group ? [1] : []

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[0].arn
    }
  }

  dynamic "condition" {
    for_each = length(var.hostnames) > 0 ? [1] : []
    content {
      host_header {
        values = var.hostnames
      }
    }
  }

  dynamic "condition" {
    for_each = length(var.path_patterns) > 0 ? [1] : []
    content {
      path_pattern {
        values = var.path_patterns
      }
    }
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-${var.stack_name}" })
}

# Only attach instances for normal forward rules
resource "aws_lb_target_group_attachment" "instances" {
  count = local.use_fixed_response ? 0 : length(var.instance_ids)

  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = var.instance_ids[count.index]
  port             = var.backend_port
}
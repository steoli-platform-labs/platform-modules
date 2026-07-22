# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Outputs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
output "target_group_arn" {
  value = try(aws_lb_target_group.this[0].arn, null)
}

output "listener_rule_arn" {
  value = aws_lb_listener_rule.this.arn
}

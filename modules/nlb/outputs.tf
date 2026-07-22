# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Outputs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
output "nlb_arn" {
  value = aws_lb.this.arn
}

output "nlb_dns_name" {
  value = aws_lb.this.dns_name
}

output "nlb_zone_id" {
  value = aws_lb.this.zone_id
}

output "listener_main_arn" {
  value = try(aws_lb_listener.main_tls[0].arn, aws_lb_listener.main_tcp[0].arn, null)
}

output "listener_ssh_arn" {
  value = try(aws_lb_listener.ssh[0].arn, null)
}

output "target_group_main_arn" {
  value = aws_lb_target_group.main.arn
}

output "target_group_ssh_arn" {
  value = try(aws_lb_target_group.ssh[0].arn, null)
}

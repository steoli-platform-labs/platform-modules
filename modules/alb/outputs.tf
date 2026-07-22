# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Outputs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
output "internal_alb_arn" {
  value = try(aws_lb.internal[0].arn, null)
}

output "internal_alb_dns_name" {
  value = try(aws_lb.internal[0].dns_name, null)
}

output "internal_alb_listener_http_arn" {
  value = try(aws_lb_listener.internal_http[0].arn, null)
}

output "internal_alb_listener_https_arn" {
  value = try(aws_lb_listener.internal_https[0].arn, null)
}

output "internal_alb_zone_id" {
  value = try(aws_lb.internal[0].zone_id, null)
}

output "external_alb_arn" {
  value = try(aws_lb.external[0].arn, null)
}

output "external_alb_dns_name" {
  value = try(aws_lb.external[0].dns_name, null)
}

output "external_alb_listener_http_arn" {
  value = try(aws_lb_listener.external_http[0].arn, null)
}

output "external_alb_listener_https_arn" {
  value = try(aws_lb_listener.external_https[0].arn, null)
}

output "external_alb_zone_id" {
  value = try(aws_lb.external[0].zone_id, null)
}

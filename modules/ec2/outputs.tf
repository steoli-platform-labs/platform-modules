# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Outputs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
output "instance_ids" {
  value = [for i in aws_instance.this : i.id]
}

output "private_ips" {
  value = [for i in aws_instance.this : i.private_ip]
}

output "additional_data_volume_ids" {
  value = {
    for k, v in aws_ebs_volume.additional_data : k => v.id
  }
}

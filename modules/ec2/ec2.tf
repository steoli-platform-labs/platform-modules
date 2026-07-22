# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# EC2
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
locals {
  letters = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]

  additional_volume_matrix = flatten([
    for instance_index in range(var.instance_count) : [
      for volume in var.additional_data_volumes : {
        key            = "${instance_index}-${volume.name}"
        instance_index = instance_index
        name           = volume.name
        size           = volume.size
        type           = volume.type
        encrypted      = volume.encrypted
        device_name    = volume.device_name
      }
    ]
  ])

  additional_volume_map = {
    for v in local.additional_volume_matrix : v.key => v
  }
}

resource "aws_instance" "this" {
  count = var.instance_count

  ami                     = trimspace(var.ami_id) != "" ? var.ami_id : data.aws_ami.ubuntu.id
  iam_instance_profile    = var.iam_instance_profile
  instance_type           = var.instance_type
  subnet_id               = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids  = var.security_group_ids
  key_name                = trimspace(var.key_name) != "" ? var.key_name : null
  disable_api_termination = var.ec2_disable_api_termination
  ebs_optimized           = true

  metadata_options {
    http_endpoint = var.ec2_http_endpoint
    http_tokens   = var.ec2_http_tokens
  }

  user_data = templatefile("${path.module}/templates/postinstall.tpl", {
    ebs_vars          = var.ebs_mount_vars,
    efs_share         = "N/A" #var.create_efs ? aws_efs_file_system.this[0].dns_name : "N/A",
    efs_mount_point   = "N/A" #var.create_efs ? var.efs_mount_point : "N/A",
    efs_mount_options = "N/A" #var.create_efs ? var.efs_mount_options : "N/A"
  })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
    tags = merge(
      var.common_tags,
      var.volume_tags,
      {
        Name = "${var.prefix}-${var.stack_name}${local.letters[count.index]}"
      }
    )
  }

  tags = merge(
    var.common_tags,
    var.instance_tags,
    {
      Name = "${var.prefix}-${var.stack_name}${local.letters[count.index]}"
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
      volume_tags,
      root_block_device[0].tags,
      user_data
    ]
  }
}

resource "aws_ebs_volume" "data" {
  count = var.instance_count

  availability_zone = aws_instance.this[count.index].availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(
    var.common_tags,
    var.volume_tags,
    {
      Name = "${var.prefix}-${var.stack_name}${local.letters[count.index]}-data"
    }
  )
}

resource "aws_volume_attachment" "data" {
  count = var.instance_count

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data[count.index].id
  instance_id = aws_instance.this[count.index].id
}

resource "aws_ebs_volume" "additional_data" {
  for_each = local.additional_volume_map

  availability_zone = aws_instance.this[each.value.instance_index].availability_zone
  size              = each.value.size
  type              = each.value.type
  encrypted         = each.value.encrypted

  tags = merge(
    var.common_tags,
    var.volume_tags,
    {
      Name = "${var.prefix}-${var.stack_name}${local.letters[each.value.instance_index]}-${each.value.name}"
    }
  )
}

resource "aws_volume_attachment" "additional_data" {
  for_each = local.additional_volume_map

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.additional_data[each.key].id
  instance_id = aws_instance.this[each.value.instance_index].id
}

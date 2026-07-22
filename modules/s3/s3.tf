# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# S3
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
locals {
  # Normalize input into a map: name_suffix => config
  # If var.buckets is a list(string), convert to map with empty config.
  buckets_map_raw = can(tolist(var.buckets)) ? {
    for s in tolist(var.buckets) : s => {}
  } : tomap(var.buckets)

  # Apply module-level defaults (e.g., lifecycle rules) unless overridden per bucket.
  buckets_map = {
    for k, v in local.buckets_map_raw : k => merge(
      v,
      {
        lifecycle_rules = try(v.lifecycle_rules, var.default_lifecycle_rules)
      }
    )
  }
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets_map

  # Final bucket name: <prefix>-<stack_name>-<key>
  bucket        = lower(replace("${var.prefix}-${var.stack_name}-${each.key}", "_", "-"))
  force_destroy = try(each.value.force_destroy, var.force_destroy)

  tags = merge(
    var.common_tags,
    try(each.value.tags, {}),
    {
      Name = lower(replace("${var.prefix}-${var.stack_name}-${each.key}", "_", "-"))
    }
  )
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id
  versioning_configuration {
    status = try(local.buckets_map[each.key].versioning, var.default_versioning) ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Strong sane default: block all public access
resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Optional lifecycle rules per bucket (can be provided per bucket or via var.default_lifecycle_rules)
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = {
    for k, v in local.buckets_map : k => v
    if try(v.lifecycle_rules, null) != null && length(v.lifecycle_rules) > 0
  }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules
    content {
      id     = try(rule.value.id, "rule-${rule.key}")
      status = try(rule.value.enabled, true) ? "Enabled" : "Disabled"

      filter {}

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_multipart_days, null) != null ? [1] : []
        content {
          days_after_initiation = rule.value.abort_multipart_days
        }
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration_days, null) != null || try(rule.value.expired_object_delete_marker, null) != null ? [1] : []
        content {
          days                         = try(rule.value.expiration_days, null)
          expired_object_delete_marker = try(rule.value.expired_object_delete_marker, null)
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_expiration_days, null) != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_expiration_days
        }
      }
    }
  }
}
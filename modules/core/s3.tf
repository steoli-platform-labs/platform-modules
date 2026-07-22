# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# S3
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
resource "random_string" "namespace" {
  length  = 4
  special = false
  upper   = false
}

# SSM
resource "aws_s3_bucket" "aws-ssm" {
  count = var.create_aws_ssm_bucket ? 1 : 0

  bucket        = "${var.prefix}-aws-ssm-${random_string.namespace.result}"
  force_destroy = true

  tags = merge(
    { Name = "${var.prefix}-aws-ssm-${random_string.namespace.result}" },
    var.common_tags
  )
}

resource "aws_s3_bucket_public_access_block" "aws-ssm" {
  count = var.create_aws_ssm_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.aws-ssm[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "aws-ssm" {
  count = var.create_aws_ssm_bucket ? 1 : 0

  bucket = aws_s3_bucket.aws-ssm[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aws-ssm" {
  count = var.create_aws_ssm_bucket ? 1 : 0

  bucket = aws_s3_bucket.aws-ssm[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# ALB accesslog
resource "aws_s3_bucket" "alb_logs" {
  count  = var.create_alb_access_logs_bucket ? 1 : 0
  bucket = "${var.prefix}-alb-access-logs-${random_string.namespace.result}"

  tags = merge(var.common_tags, { Name = "${var.prefix}-alb-access-logs" })
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count                   = var.create_alb_access_logs_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.alb_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  count  = var.create_alb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  count  = var.create_alb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.create_alb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow log delivery service to verify bucket ACL
      {
        Sid    = "AWSLogDeliveryAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.alb_logs[0].arn,
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },

      # Allow log delivery to write objects
      {
        Sid    = "AWSLogDeliveryWrite",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control",
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },

      # Legacy/compat: allow the regional ELB service account as well
      {
        Sid    = "ELBServiceAccountWrite",
        Effect = "Allow",
        Principal = {
          AWS = data.aws_elb_service_account.this.arn
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.alb_logs,
    aws_s3_bucket_ownership_controls.alb_logs
  ]
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  count  = var.create_alb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  count  = var.create_alb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "expire-alb-logs"
    status = "Enabled"

    filter {} # apply to whole bucket

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}


# NLB
resource "aws_s3_bucket" "nlb_logs" {
  count  = var.create_nlb_access_logs_bucket ? 1 : 0
  bucket = "${var.prefix}-nlb-access-logs-${random_string.namespace.result}"

  tags = merge(var.common_tags, { Name = "${var.prefix}-nlb-access-logs" })
}

resource "aws_s3_bucket_public_access_block" "nlb_logs" {
  count                   = var.create_nlb_access_logs_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.nlb_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nlb_logs" {
  count  = var.create_nlb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.nlb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "nlb_logs" {
  count  = var.create_nlb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.nlb_logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "nlb_logs" {
  count  = var.create_nlb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.nlb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSLogDeliveryAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.nlb_logs[0].arn,
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryWrite",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.nlb_logs[0].arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control",
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "ELBServiceAccountWrite",
        Effect = "Allow",
        Principal = {
          AWS = data.aws_elb_service_account.this.arn
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.nlb_logs[0].arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.nlb_logs,
    aws_s3_bucket_ownership_controls.nlb_logs
  ]
}

resource "aws_s3_bucket_versioning" "nlb_logs" {
  count  = var.create_nlb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.nlb_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "nlb_logs" {
  count  = var.create_nlb_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.nlb_logs[0].id

  rule {
    id     = "expire-nlb-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

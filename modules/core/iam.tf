# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# IAM
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# EC2
resource "aws_iam_role" "instance_role" {
  count = var.create_operational_baseline ? 1 : 0

  name = "${var.prefix}-InstanceRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : ["sts:AssumeRole"],
        "Effect" : "allow",
        "Principal" : {
          "Service" : ["ec2.amazonaws.com"]
        }
      }
    ]
  })
}

locals {
  iam_instance_role_policies = var.create_operational_baseline ? {
    "amazon_ssm_managed_instance_core" : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "cloudwatch_agent_server_policy" : "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "gitlab_policy" : aws_iam_policy.gitlab[0].arn,
  } : {}
}

resource "aws_iam_role_policy_attachment" "instance_role_policies" {
  for_each   = local.iam_instance_role_policies
  role       = aws_iam_role.instance_role[0].name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "instance_profile" {
  count = var.create_operational_baseline ? 1 : 0

  name = "${var.prefix}-InstanceProfile"
  role = aws_iam_role.instance_role[0].name
}


# Gitlab
resource "aws_iam_policy" "gitlab" {
  count = var.create_operational_baseline ? 1 : 0

  name        = "${var.prefix}-gitlab"
  path        = "/"
  description = "${var.prefix} Gitlab policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpDelete",
          "es:ESHttpGet",
          "es:ESHttpHead",
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpPatch",
        ]
        Resource = "arn:aws:es::${data.aws_caller_identity.current.account_id}:domain/elasticsearch*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:GetObjectTagging"
        ]
        Resource = "arn:aws:s3:::${var.prefix}-*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::${var.prefix}-*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
        ]
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetEncryptionConfiguration"
        ],
        "Resource" : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ds:CreateComputer",
          "ds:DescribeDirectories"
        ],
        "Resource" : "*"
      },
    ]
  })
}


# Instance scheduler
resource "aws_iam_role" "instance_scheduler" {
  count = var.create_instance_scheduler ? 1 : 0

  name = "${var.prefix}-InstanceSchedulerRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "instance_scheduler_policies" {
  count = var.create_instance_scheduler ? 1 : 0

  role       = aws_iam_role.instance_scheduler[0].name
  policy_arn = aws_iam_policy.instance_scheduler[0].arn
}

resource "aws_iam_policy" "instance_scheduler" {
  count = var.create_instance_scheduler ? 1 : 0

  name = "${var.prefix}_InstanceScheduler_Policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:Start*",
          "ec2:Stop*",
          "ec2:CreateTags"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource",
          "rds:StartDBInstance",
          "rds:StopDBInstance",
          "rds:AddTagsToResource"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:CreateOrUpdateTags"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# AWS Backup
resource "aws_iam_role" "backup" {
  count = var.create_backup_vault ? 1 : 0

  name = "${var.prefix}-BackupRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : ["sts:AssumeRole"],
        "Effect" : "allow",
        "Principal" : {
          "Service" : ["backup.amazonaws.com"]
        }
      }
    ]
  })
}

locals {
  iam_backup_role_policies = var.create_backup_vault ? {
    "servicerolepolicy_backup" : "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "servicerolepolicy_restore" : "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
    "servicerolepolicy_s3_backup" : "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup",
    "servicerolepolicy_s3_restore" : "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore",
    "restore_policy" : aws_iam_policy.restore[0].arn,
    "kms_policy" : aws_iam_policy.kms[0].arn,
  } : {}
}

resource "aws_iam_role_policy_attachment" "backup_role_policies" {
  for_each   = local.iam_backup_role_policies
  role       = aws_iam_role.backup[0].name
  policy_arn = each.value
}


resource "aws_iam_policy" "kms" {
  count = var.create_backup_vault ? 1 : 0

  name        = "${var.prefix}-kms"
  path        = "/"
  description = "${var.prefix} KMS policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
        ]
        Resource = [
          "*"
        ]
      },
    ]
  })
}

resource "aws_iam_policy" "restore" {
  count = var.create_backup_vault ? 1 : 0

  name        = "${var.prefix}-restore"
  path        = "/"
  description = "${var.prefix} Restore policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "*"
        ]
      },
    ]
  })
}

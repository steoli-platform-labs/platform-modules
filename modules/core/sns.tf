# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# SNS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Backup Topic
resource "aws_sns_topic" "backup" {
  count = var.create_backup_vault ? var.create_backup_sns_topic ? 1 : 0 : 0

  name = "${var.prefix}-backup"
  tags = var.common_tags
}

resource "aws_sns_topic_policy" "backup" {
  count = var.create_backup_vault ? var.create_backup_sns_topic ? 1 : 0 : 0

  arn    = aws_sns_topic.backup[0].arn
  policy = data.aws_iam_policy_document.sns_backup[0].json
}

resource "aws_sns_topic_subscription" "backup" {
  count = var.create_backup_vault ? var.create_backup_sns_topic ? 1 : 0 : 0

  topic_arn              = aws_sns_topic.backup[0].arn
  protocol               = var.sns_protocol
  endpoint               = var.sns_subscriber
  endpoint_auto_confirms = var.sns_subscriber_auto_confirms
  filter_policy          = <<EOF
  {
    "State": [{"anything-but":"COMPLETED"}]
  }
  EOF
}

data "aws_iam_policy_document" "sns_backup" {
  count = var.create_backup_vault ? var.create_backup_sns_topic ? 1 : 0 : 0

  policy_id = "__default_policy_ID"

  statement {
    sid = "BackupSNSPublishingPermissions"

    effect = "Allow"

    actions = [
      "SNS:Publish"
    ]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.backup[0].arn,
    ]
  }
}

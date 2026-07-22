# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Backup
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Backup Vault
resource "aws_backup_vault" "this" {
  count = var.create_backup_vault ? 1 : 0

  name = "${var.prefix}-BackupVault"
}

# Backup Vault Policy
resource "aws_backup_vault_policy" "this" {
  count = var.create_backup_vault ? var.create_backup_vault_policy ? 1 : 0 : 0

  backup_vault_name = aws_backup_vault.this[0].name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "default",
  "Statement": [
    {
      "Sid": "default",
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "backup:DeleteBackupVault",
        "backup:DeleteBackupVaultAccessPolicy",
        "backup:DeleteRecoveryPoint",
        "backup:PutBackupVaultAccessPolicy",
        "backup:UpdateRecoveryPointLifecycle"
      ],
      "Resource": "${aws_backup_vault.this[0].arn}"
    }
  ]
}
POLICY
}

# Backup Plan
resource "aws_backup_plan" "this" {
  count = var.create_backup_vault ? 1 : 0

  name = "${var.prefix}-BackupPlan"

  dynamic "rule" {
    for_each = var.backup_plan_rules
    content {
      rule_name         = rule.value.name
      target_vault_name = aws_backup_vault.this[0].name
      schedule          = rule.value.schedule
      start_window      = rule.value.start_window
      completion_window = rule.value.completion_window

      lifecycle {
        delete_after = var.backup_expire_days > 0 ? var.backup_expire_days : rule.value.expire_days
      }

      dynamic "copy_action" {
        for_each = var.create_backup_copy ? [1] : []
        content {
          destination_vault_arn = "arn:aws:backup:${var.backup_copy_region}:${data.aws_caller_identity.current.account_id}:backup-vault:Default"
          lifecycle {
            delete_after = rule.value.copy_expire_days
          }
        }
      }
    }
  }
}

# Backup Selection
resource "aws_backup_selection" "this" {
  count = var.create_backup_vault ? 1 : 0

  name         = "${var.prefix}-BackupSelection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.this[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_selection_tag["key"]
    value = var.backup_selection_tag["value"]
  }
}

# Backup Region Settings
locals {
  advanced_regions = ["us-east-1", "us-west-2", "eu-central-1", "eu-west-1"]
}

# Event notifications
resource "aws_backup_vault_notifications" "backup" {
  count = var.create_backup_vault ? var.create_backup_sns_topic ? 1 : 0 : 0

  backup_vault_name   = aws_backup_vault.this[0].name
  sns_topic_arn       = aws_sns_topic.backup[0].arn
  backup_vault_events = ["BACKUP_JOB_COMPLETED", "COPY_JOB_FAILED", "S3_BACKUP_OBJECT_FAILED"]
}

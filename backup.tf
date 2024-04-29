locals {
  is_backup_enabled            = var.backup_enabled == "on"
  is_continuous_backup_enabled = var.continuous_backup_enabled == "on"
  export_schedule_expression   = var.backup_frequency == "weekly" ? "cron(0 0 ? * SUN *)" : (var.backup_frequency == "monthly" ? "cron(0 0 1 * ? *)" : "cron(0 0 * * ? *)")
}

resource "aws_iam_role" "backup" {
  count = local.is_backup_enabled || local.is_continuous_backup_enabled ? 1 : 0

  name = "${var.env}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup",
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  ]
}

resource "aws_backup_vault" "vault" {
  count = local.is_backup_enabled ? 1 : 0

  name          = "${var.env}-backup-vault"
  force_destroy = true
}

resource "aws_backup_vault" "vault-replica" {
  count = local.is_backup_enabled ? 1 : 0

  provider      = aws.backup_region
  name          = "${var.env}-backup-vault-replica"
  force_destroy = true
}

resource "aws_backup_selection" "ec2" {
  count = local.is_backup_enabled ? 1 : 0

  name         = "${var.env}-ec2-selection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.plan[0].id
  resources    = ["${aws_instance.mongodb.arn}"]
}

resource "aws_backup_selection" "rds" {
  count = local.is_backup_enabled ? 1 : 0

  name         = "${var.env}-rds-selection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.plan[0].id
  resources    = ["${aws_db_instance.this.arn}"]
}

resource "aws_backup_selection" "dynamodb" {
  count = local.is_backup_enabled ? 1 : 0

  name         = "${var.env}-dynamodb-selection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.plan[0].id
  resources = [
    "${aws_dynamodb_table.prototype_accounts.arn}",
    "${aws_dynamodb_table.prototype_submissions.arn}",
    "${aws_dynamodb_table.audit_accounts.arn}",
    "${aws_dynamodb_table.audit_submissions.arn}",
    "${aws_dynamodb_table.communication_details.arn}",
    "${aws_dynamodb_table.communication_batches.arn}",
    "${aws_dynamodb_table.communication_delivery_events.arn}"
  ]
}

resource "aws_backup_selection" "s3" {
  count = local.is_backup_enabled ? 1 : 0

  name         = "${var.env}-s3-selection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.plan[0].id
  resources = [
    "${aws_s3_bucket.atribo-config-bucket.arn}",
    "${aws_s3_bucket.reach-atribo-dms-bucket.arn}",
    "${aws_s3_bucket.atribo-log-backup-bucket[0].arn}"
  ]
}

resource "aws_backup_plan" "plan" {
  count = local.is_backup_enabled ? 1 : 0

  name = "${var.env}-${var.backup_frequency}"

  dynamic "rule" {
    for_each = var.backup_frequency == "daily" ? [1] : []

    content {
      rule_name         = "daily-rule"
      target_vault_name = "${var.env}-backup-vault"
      schedule          = "cron(0 0 * * ? *)"
      start_window      = 60
      completion_window = 1440


      copy_action {
        destination_vault_arn = aws_backup_vault.vault-replica[0].arn
        lifecycle {
          delete_after = var.backup_retention
        }
      }

      lifecycle {
        delete_after = var.backup_retention
      }
    }
  }

  dynamic "rule" {
    for_each = var.backup_frequency == "weekly" ? [1] : []

    content {
      rule_name         = "weekly-rule"
      target_vault_name = "${var.env}-backup-vault"
      schedule          = "cron(0 0 * * SUN *)"
      start_window      = 60
      completion_window = 1440
      copy_action {
        destination_vault_arn = aws_backup_vault.vault-replica[0].arn
        lifecycle {
          delete_after = var.backup_retention
        }
      }

      lifecycle {
        delete_after = var.backup_retention
      }
    }
  }

  dynamic "rule" {
    for_each = var.backup_frequency == "monthly" ? [1] : []

    content {
      rule_name         = "monthly-rule"
      target_vault_name = "${var.env}-backup-vault"
      schedule          = "cron(0 0 1 * ? *)"
      start_window      = 60
      completion_window = 1440
      copy_action {
        destination_vault_arn = aws_backup_vault.vault-replica[0].arn
        lifecycle {
          delete_after = var.backup_retention
        }
      }

      lifecycle {
        delete_after = var.backup_retention
      }
    }
  }

  depends_on = [aws_backup_vault.vault, aws_backup_vault.vault-replica]
}

// Log backup configuration

resource "aws_iam_role" "kinesis_delivery_role" {
  count = local.is_backup_enabled ? 1 : 0

  name = "${var.env}-log-backup-kinesis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
}

resource "aws_iam_role" "backup_logs_to_kinesis_role" {
  count = local.is_backup_enabled ? 1 : 0

  name = "${var.env}-backup-logs-to-kinesis-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "backup_logs_firehose_policy" {
  count = local.is_backup_enabled ? 1 : 0

  name = "${var.env}-backup-logs-firehose-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_logs_to_kinesis_role_policy_attachment" {
  count = local.is_backup_enabled ? 1 : 0

  policy_arn = aws_iam_policy.backup_logs_firehose_policy[0].arn
  role       = aws_iam_role.backup_logs_to_kinesis_role[0].name
}

resource "aws_s3_bucket" "atribo-log-backup-bucket" {
  count = local.is_backup_enabled ? 1 : 0

  bucket        = "reach-atribo-log-backup-${var.env}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning-log-backup-bucket" {
  count = local.is_backup_enabled ? 1 : 0

  bucket = aws_s3_bucket.atribo-log-backup-bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "atribo-log-backup-bucket" {
  count = local.is_backup_enabled ? 1 : 0

  bucket = aws_s3_bucket.atribo-log-backup-bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "atribo-log-backup-bucket" {
  count = local.is_backup_enabled ? 1 : 0

  bucket = aws_s3_bucket.atribo-log-backup-bucket[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "app_logs_delivery_stream" {
  count = local.is_backup_enabled ? 1 : 0

  name        = "${var.env}-app-logs-backup-delivery-stream"
  destination = "s3"

  s3_configuration {
    role_arn        = aws_iam_role.kinesis_delivery_role[0].arn
    bucket_arn      = aws_s3_bucket.atribo-log-backup-bucket[0].arn
    prefix          = "${var.env}-app-logs-backup/"
    buffer_size     = 128
    buffer_interval = 300
  }
}

resource "aws_kinesis_firehose_delivery_stream" "traffic_logs_delivery_stream" {
  count = local.is_backup_enabled ? 1 : 0

  name        = "${var.env}-traffic-logs-backup-delivery-stream"
  destination = "s3"

  s3_configuration {
    role_arn        = aws_iam_role.kinesis_delivery_role[0].arn
    bucket_arn      = aws_s3_bucket.atribo-log-backup-bucket[0].arn
    prefix          = "${var.env}-traffic-logs-backup/"
    buffer_size     = 128
    buffer_interval = 300
  }
}

resource "aws_kinesis_firehose_delivery_stream" "squidex_logs_delivery_stream" {
  count = local.is_backup_enabled ? 1 : 0

  name        = "${var.env}-squidex-logs-backup-delivery-stream"
  destination = "s3"

  s3_configuration {
    role_arn        = aws_iam_role.kinesis_delivery_role[0].arn
    bucket_arn      = aws_s3_bucket.atribo-log-backup-bucket[0].arn
    prefix          = "${var.env}-squidex-logs-backup/"
    buffer_size     = 128
    buffer_interval = 300
  }
}

resource "aws_cloudwatch_log_subscription_filter" "app_logs_subscription_filter" {
  count = local.is_backup_enabled ? 1 : 0

  name            = "${var.env}-app-logs-subscription-filter"
  role_arn        = aws_iam_role.backup_logs_to_kinesis_role[0].arn
  log_group_name  = aws_cloudwatch_log_group.app_log_group.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.app_logs_delivery_stream[0].arn
}

resource "aws_cloudwatch_log_subscription_filter" "traffic_logs_subscription_filter" {
  count = local.is_backup_enabled ? 1 : 0

  name            = "${var.env}-traffic-logs-subscription-filter"
  role_arn        = aws_iam_role.backup_logs_to_kinesis_role[0].arn
  log_group_name  = aws_cloudwatch_log_group.traffic_log_group.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.traffic_logs_delivery_stream[0].arn
}

resource "aws_cloudwatch_log_subscription_filter" "squidex_logs_subscription_filter" {
  count = local.is_backup_enabled ? 1 : 0

  name            = "${var.env}-squidex-logs-subscription-filter"
  role_arn        = aws_iam_role.backup_logs_to_kinesis_role[0].arn
  log_group_name  = module.squidex-deploy.squidex_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.squidex_logs_delivery_stream[0].arn
}

# resource "aws_cloudformation_stack" "cognito-backup" {
#   count        = local.is_backup_enabled ? 1 : 0
#   name         = "${var.env}-cognito-backup"
#   template_url = "https://s3.amazonaws.com/solutions-reference/cognito-user-profiles-export-reference-architecture/latest/cognito-user-profiles-export-reference-architecture.template"
#   capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
#   parameters = {
#     PrimaryUserPoolId = values(module.api)[0].cognito_id
#     SecondaryRegion   = var.backup_region
#     ExportFrequency   = var.backup_frequency == "weekly" ? "EVERY_7_DAYS" : (var.backup_frequency == "monthly" ? "EVERY_30_DAYS" : "EVERY_DAY")
#     CognitoTPS        = 10
#     NotificationEmail = "webmaster@thereachagency.com"
#     # SnsPreference = "" // Default value - "INFO_AND_ERRORS". Other option is "ERRORS_ONLY".
#   }
# }

locals{
      cognito_pool_id = {
     for project in var.project_version : project.project => module.api[project.project].cognito_id
    }
  
}

module "cognito_backup"{
  #for_each = module.api
  for_each           = local.cognito_pool_id
  source = "./modules/cognito_backup"
  backup_frequency = var.backup_frequency
  backup_region =var.backup_region
  backup_enabled = var.backup_enabled
  env=var.env
  cognito_pool_id=each.value
  name = each.key

}
resource "null_resource" "update_rule_cron" {
  count = local.is_backup_enabled ? 1 : 0
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
     rule_name=$(aws events list-rules --region ${var.region} --name-prefix StackSet-${var.env} --query 'Rules[0].Name' --output text)
     aws events put-rule --region ${var.region} --name $rule_name --schedule-expression "${local.export_schedule_expression}"
      EOT
  }
  depends_on = [module.cognito_backup, null_resource.config_auto_update]
}


########-Continuous Backup plan-############

resource "aws_backup_vault" "continuous_backup_vault" {
  count = local.is_continuous_backup_enabled ? 1 : 0

  name          = "${var.env}-continuous-backup-vault"
  force_destroy = true
}
resource "aws_backup_vault" "continuous_backup_vault_replica" {
  count = local.is_continuous_backup_enabled ? 1 : 0

  provider      = aws.backup_region
  name          = "${var.env}-continuous-backup-vault-replica"
  force_destroy = true
}

resource "aws_backup_selection" "rds_selection" {
  count = local.is_continuous_backup_enabled ? 1 : 0

  name         = "${var.env}-rds-selection-continuous"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.continuous_backup_plan[0].id
  resources    = ["${aws_db_instance.this.arn}"]
}
resource "aws_backup_selection" "s3_selection" {
  count = local.is_continuous_backup_enabled ? 1 : 0

  name         = "${var.env}-s3-selection-continuous"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.continuous_backup_plan[0].id
  resources = [
    "${aws_s3_bucket.atribo-config-bucket.arn}",
    "${aws_s3_bucket.reach-atribo-dms-bucket.arn}"
  ]
}
resource "aws_backup_plan" "continuous_backup_plan" {
  count = local.is_continuous_backup_enabled ? 1 : 0
  name  = "${var.env}-continuous-backup-plan"
  rule {
    rule_name                = "${var.env}-continuous-backup-rule"
    target_vault_name        = "${var.env}-continuous-backup-vault"
    schedule                 = "cron(0 0 * * ? *)"
    start_window             = 60
    completion_window        = 1440
    enable_continuous_backup = true


    copy_action {
      destination_vault_arn = aws_backup_vault.continuous_backup_vault_replica[0].arn
      lifecycle {
        delete_after = var.continuous_backup_retention
      }
    }
    lifecycle {
      delete_after = var.continuous_backup_retention
    }
  }
  depends_on = [aws_backup_vault.continuous_backup_vault, aws_backup_vault.continuous_backup_vault_replica]
}



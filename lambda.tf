resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.DMS_Notification.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.reach-atribo-dms-bucket.arn
}

resource "aws_lambda_function" "DynamoDBSnapshotSchemaManager" {
  #  filename      = "lambda_function_payload.zip"
  function_name = "${var.env}-DynamoDBSnapshotSchemaManager"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/dynamodb-snapshot-schema-manager-lambda:${local.dynamodb-ssm-lambda_version}"
  timeout       = 60

  image_config {
    entry_point       = ["/lambda-entrypoint.sh"]
    command           = ["Atribo.Lambdas.DynamoDBSnapshotSchemaManager::Atribo.Lambdas.DynamoDBSnapshotSchemaManager.Function::HandleAsync"]
    working_directory = "/var/task"
  }

  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_dynamo_access_policy]
}

resource "aws_lambda_function" "DynamoDBStreamHandler" {
  #  filename      = "lambda_function_payload.zip"
  function_name = "${var.env}-DynamoDBStreamHandler"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/dynamodb-stream-handler-lambda:${local.dynamodb-sh-lambda_version}"
  timeout       = 60

  image_config {
    entry_point       = ["/lambda-entrypoint.sh"]
    command           = ["Atribo.Lambdas.DynamoDBStreamHandler::Atribo.Lambdas.DynamoDBStreamHandler.Function::HandleAsync"]
    working_directory = "/var/task"
  }

  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_dynamo_access_policy]
}

/* ATRIBO-10846 Remove seeding Lambdas for SM, DMS, AtriboCore
resource "aws_lambda_function" "DatabaseSeedingPortal" {
  #  filename      = "lambda_function_payload.zip"
  function_name = "${var.env}-DatabaseSeedingPortal"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/db-seeding-portal-lambda:${local.db-seeding-portal-lambda_version}"
  timeout = 120

  image_config {
    entry_point       = ["/lambda-entrypoint.sh"]
    command           = ["Atribo.Serverless.DatabaseSeeding.Portal::Atribo.Serverless.DatabaseSeeding.Portal.PortalSeedingFunction::HandleAsync"]
    working_directory = "/var/task"
  }

  environment {
    variables = {
      env = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_function" "DatabaseSeedingDMS" {
  #  filename      = "lambda_function_payload.zip"
  function_name = "${var.env}-DatabaseSeedingDMS"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/db-seeding-dms-lambda:${local.db-seeding-dms-lambda_version}"
  timeout = 120

  image_config {
    entry_point       = ["/lambda-entrypoint.sh"]
    command           = ["Atribo.Serverless.DatabaseSeeding.DMS::Atribo.Serverless.DatabaseSeeding.DMS.DmsSeedingLambdaHost::HandleAsync"]
    working_directory = "/var/task"
  }

  environment {
    variables = {
      env = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_function" "DatabaseSeedingIdentity" {
  #  filename      = "lambda_function_payload.zip"
  function_name = "${var.env}-DatabaseSeedingIdentity"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/db-seeding-identity-lambda:${local.db-seeding-identity-lambda_version}"
  timeout = 120

  image_config {
    entry_point       = ["/lambda-entrypoint.sh"]
    command           = ["Atribo.Serverless.DatabaseSeeding.Identity::Atribo.Serverless.DatabaseSeeding.Identity.IdentitySeedingLambdaHost::HandleAsync"]
    working_directory = "/var/task"
  }

  environment {
    variables = {
      env = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}


resource "aws_lambda_invocation" "seeding_portal" {
  function_name = aws_lambda_function.DatabaseSeedingPortal.function_name

  input = jsonencode({
    payload = "seeding"
  })

  depends_on = [aws_lambda_function.DatabaseSeedingPortal, aws_ssm_parameter.common_database_url, aws_lambda_invocation.seed_users]
}

resource "aws_lambda_invocation" "seeding_dms" {
  function_name = aws_lambda_function.DatabaseSeedingDMS.function_name

  input = jsonencode({
    payload = "seeding"
  })

  depends_on = [aws_lambda_function.DatabaseSeedingDMS, aws_ssm_parameter.common_database_url, aws_lambda_invocation.seed_users]
}

resource "aws_lambda_invocation" "seeding_identity" {
  function_name = aws_lambda_function.DatabaseSeedingIdentity.function_name

  input = jsonencode({
    payload = "seeding"
  })

  depends_on = [aws_lambda_function.DatabaseSeedingIdentity, aws_ssm_parameter.common_database_url, aws_lambda_invocation.seed_users]
}*/


resource "aws_lambda_function" "DMS_Notification" {
  #  filename      = "lambda_function_payload.zip"
  function_name = "${var.env}-DMS_Notification"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/dms-notification-lambda:${local.dms-notification-lambda_version}"
  timeout       = 60

  memory_size = 512
  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_function" "surveyformvalidator" {
  function_name = "${var.env}-surveyformvalidator"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/survey-form-validator-lambda:${local.survey-form-validator-lambda_version}"
  timeout       = 30

  memory_size = 512
  environment {
    variables = {
      env           = var.env
      domain        = var.domain
      ContentApiUrl = "https://${var.dns_name}.${var.domain}"
      siteKey       = var.google_recaptcha_site_key
      secretKey     = var.google_recaptcha_secret_key
      #      siteKey = aws_ssm_parameter.common_GoogleReCaptcharSiteKey.value
      #      secretKey = aws_ssm_parameter.common_GoogleReCaptcharSecrectKey.value
      RecaptchaValidationEnabled = "true"
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# resource "aws_lambda_function" "SendEmailFunction" {
#   #  filename      = "lambda_function_payload.zip"
#   function_name = "${var.env}-SendEmailFunction"
#   role          = aws_iam_role.lambda_role.arn
#   package_type  = "Image"
#   image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-ses-lambda:latest"
#   timeout = 60
#
#
#   environment {
#     variables = {
#       env = var.env
#     }
#   }
#
#   vpc_config {
#     subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
#     security_group_ids = [aws_security_group.lambda_sg.id]
#   }
# }
#
# resource "aws_lambda_function" "SendSmsFunction" {
#   #  filename      = "lambda_function_payload.zip"
#   function_name = "${var.env}-SendSmsFunction"
#   role          = aws_iam_role.lambda_role.arn
#   package_type  = "Image"
#   image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-sms-lambda:latest"
#   timeout = 60
#
#   environment {
#     variables = {
#       env = var.env
#     }
#   }
#
#   vpc_config {
#     subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
#     security_group_ids = [aws_security_group.lambda_sg.id]
#   }
# }

resource "aws_lambda_function" "Cognito_Create_Auth" {
  function_name = "${var.env}-cognitocreateauth"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/cognito-create-auth-lambda:${local.cognito-create-auth-lambda_version}"
  timeout       = 40

  memory_size = 512

  environment {
    variables = {
      env                               = var.env
      domain                            = var.domain
      ConfigurationService__BaseAddress = "http://config-service.${var.domain}"
      CoreAPIsSettings__BaseURL         = "https://atribo-identity.${var.domain}/api/coreapis/"
      CoreAPIsSettings__ClientId        = "DefaultClient"
      SmsSenderId                       = aws_iam_access_key.sns.id
      SmsSenderPass                     = aws_iam_access_key.sns.secret
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_permission" "Cognito_Create_Auth" {
  for_each = module.api
  statement_id  = "AllowExecutionFromCognito_Cognito_Create_Auth_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Cognito_Create_Auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = each.value.cognito_arn
  depends_on    = [aws_lambda_function.Cognito_Create_Auth]
}

resource "aws_lambda_function" "Cognito_Define_Auth" {
  function_name = "${var.env}-cognitodefineauth"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/cognito-define-auth-lambda:${local.cognito-define-auth-lambda_version}"
  timeout       = 40

  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_permission" "Cognito_Define_Auth" {
  for_each = module.api
  statement_id  = "AllowExecutionFromCognito_Cognito_Define_Auth_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Cognito_Define_Auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = each.value.cognito_arn
  depends_on    = [aws_lambda_function.Cognito_Define_Auth]
}

resource "aws_lambda_function" "Cognito_Pre_Sign_Up" {
  function_name = "${var.env}-cognitopresignup"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/cognito-pre-sign-up-lambda:${local.cognito-pre-sign-up-lambda_version}"
  timeout       = 40

  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_permission" "Cognito_Pre_Sign_Up" {
  for_each = module.api
  statement_id  = "AllowExecutionFromCognito_Cognito_Pre_Sign_Up_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Cognito_Pre_Sign_Up.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = each.value.cognito_arn
  depends_on    = [aws_lambda_function.Cognito_Pre_Sign_Up]
}

resource "aws_lambda_function" "Cognito_Verify_Auth" {
  function_name = "${var.env}-cognitoverifyauth"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/cognito-verify-auth-lambda:${local.cognito-verify-auth-lambda_version}"
  timeout       = 40

  memory_size = 512

  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_permission" "Cognito_Verify_Auth" {
  for_each = module.api
  statement_id  = "AllowExecutionFromCognito_Cognito_Verify_Auth_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Cognito_Verify_Auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = each.value.cognito_arn
  depends_on    = [aws_lambda_function.Cognito_Verify_Auth]
}

resource "aws_lambda_function" "Cognito_Pre_Auth" {
  function_name = "${var.env}-cognitopreauth"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/cognito-pre-authentication-lambda:${local.cognito-pre-authentication-lambda_version}"
  timeout       = 40
  publish       = true
  memory_size   = 1024

  environment {
    variables = {
      env                               = var.env
      domain                            = var.domain
      ConfigurationService__BaseAddress = "http://config-service.${var.domain}"
      CoreAPIsSettings__BaseURL         = "https://atribo-identity.${var.domain}/api/coreapis/"
      CoreAPIsSettings__ClientId        = "DefaultClient"
      SmsSenderId                       = aws_iam_access_key.sns.id
      SmsSenderPass                     = aws_iam_access_key.sns.secret
      WhatsAppAccountSid                = aws_ssm_parameter.whatsapp_account_sid.value
      WhatsAppAuthToken                 = aws_ssm_parameter.whatsapp_auth_token.value
      WhatsAppFromPhoneNumber           = aws_ssm_parameter.whatsapp_from_phone_number.value
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_alias" "lambda_alias" {
  name             = "latest"
  function_name    = aws_lambda_function.Cognito_Pre_Auth.function_name
  function_version = aws_lambda_function.Cognito_Pre_Auth.version
}
resource "aws_lambda_provisioned_concurrency_config" "cognito_pre_auth_concurrency" {
  function_name                     = aws_lambda_alias.lambda_alias.function_name
  provisioned_concurrent_executions = 3
  qualifier                         = aws_lambda_alias.lambda_alias.name
  depends_on                        = [aws_lambda_function.Cognito_Pre_Auth]
}

resource "aws_lambda_permission" "Cognito_Pre_Auth" {
  for_each = module.api
  statement_id  = "AllowExecutionFromCognito_Cognito_Pre_Auth_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Cognito_Pre_Auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = each.value.cognito_arn
  depends_on    = [aws_lambda_function.Cognito_Pre_Auth]
}
#Event Rule that triggers Pre-Auth Lambda function every 5 minutes
# resource "aws_cloudwatch_event_rule" "lambda_warmup_rule" {
#   name        = "${var.env}-lambda-warmup-rule"
#   description = "Keep Lambda warm by triggering a periodic event"
#   schedule_expression = "cron(0/5 * * * ? *)"
#  }
#  resource "aws_lambda_permission" "allow_event_rule_invoke_PreAuth_lambda" {
#   statement_id  = "AllowEventRuleInvokeLambda"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.Cognito_Pre_Auth.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.lambda_warmup_rule.arn
# }
# resource "aws_cloudwatch_event_target" "lambda_warmup_target" {
#   rule      = aws_cloudwatch_event_rule.lambda_warmup_rule.name
#   target_id = "lambda"
#   arn       = aws_lambda_function.Cognito_Pre_Auth.arn
# }

resource "aws_lambda_function" "Cognito_Post_Auth" {
  function_name = "${var.env}-cognitopostauth"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/cognito-post-authentication-lambda:${local.cognito-post-authentication-lambda_version}"
  timeout       = 40

  memory_size = 512

  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_permission" "Cognito_Post_Auth" {
  for_each = module.api
  statement_id  = "AllowExecutionFromCognito_Cognito_Post_Auth_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Cognito_Post_Auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = each.value.cognito_arn
  depends_on    = [aws_lambda_function.Cognito_Post_Auth]
}

resource "aws_lambda_function" "SeedUsersFunction" {
  filename         = "${path.module}/seed-lambda/SeedUsers.zip"
  function_name    = "${var.env}-SeedUsersFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "SeedUsersLambda::SeedUsersLambda.Function::FunctionHandler"
  package_type     = "Zip"
  timeout          = 60
  source_code_hash = filebase64sha256("${path.module}/seed-lambda/SeedUsers.zip")
  runtime          = "dotnet6"
  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_invocation" "seed_users" {
  function_name = aws_lambda_function.SeedUsersFunction.function_name

  input = "\"\""

  depends_on = [aws_lambda_function.SeedUsersFunction, aws_ssm_parameter.common_database_url]
}

#Audit lambda
resource "aws_lambda_function" "AuditLambda" {
  #  filename      = "lambda_function_payload.zip"
  function_name = "${var.env}-auditlambda"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/audit-lambda:${local.audit-lambda_version}"
  timeout       = 60

  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_dynamo_access_policy]
}

#SetupUser Lambda
resource "aws_lambda_function" "Setup_User" {
  function_name = "${var.env}-SetupUser"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-setupuser-lambda:${local.sm_setupuser_lambda_version}"
  timeout       = 40

  memory_size = 512

  environment {
    variables = {
      env = var.env
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

#MessageQueue Lambda
resource "aws_lambda_function" "Message_Queue" {
  function_name = "${var.env}-ProjectMessageQueue"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-messagequeue-lambda:${local.sm_messagequeue_lambda_version}"
  timeout       = 900

  memory_size = 512

  environment {
    variables = {
      env = var.env
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.terraform_queue.arn
  function_name    = aws_lambda_function.Message_Queue.arn
  batch_size       = 1
}

#UserIdentifier Lambda
resource "aws_lambda_function" "User_Identifier" {
  function_name = "${var.env}-UserIdentifier"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-useridentifier-lambda:${local.sm_useridentifier_lambda_version}"
  timeout       = 40

  memory_size = 512

  environment {
    variables = {
      env = var.env
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_permission" "user_identifier_permission" {
  for_each = module.api
  statement_id  = "user_identifier_permission_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.User_Identifier.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${each.value.api_arn}/*/*/user-identifier"
}

#ECS Service update lambda
data "archive_file" "ecs_service_update_lambda_function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambda/ecs-service-update-lambda"
  output_path = "${path.module}/src/lambda/ecs-service-update-lambda.zip"
}

resource "aws_lambda_function" "ecs_service_update_lambda" {
  filename      = "${path.module}/src/lambda/ecs-service-update-lambda.zip"
  function_name = "${var.env}-ecs-service-update-lambda"
  description   = "Updates ECS service"
  handler       = "ecs-service-update-lambda.lambda_handler"
  role          = aws_iam_role.ecs_service_update_lambda_role.arn
  runtime       = "python3.9"

  source_code_hash = data.archive_file.ecs_service_update_lambda_function_zip.output_base64sha256

  environment {
    variables = {
      ECS_CLUSTER_NAME = "${var.env}-cluster"
      ECS_SERVICE_NAME = "${var.env}-sm-portal-api"
    }
  }
}

# resource "aws_scheduler_schedule" "ecs_service_update_schedule" {
#   name       = "${var.env}-ecs-service-update-schedule"
#   group_name = "default"

#   flexible_time_window {
#     mode = "OFF"
#   }

#   schedule_expression = "cron(0 * * * ? *)"

#   target {
#     arn      = aws_lambda_function.ecs_service_update_lambda.arn
#     role_arn = aws_iam_role.eventbridge_invoke_lambda_role.arn
#   }
# }

resource "aws_cloudwatch_metric_alarm" "ecs_memory_alarm" {
  alarm_name          = "${var.env}-ecs-memory-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "65"

  dimensions = {
    ServiceName = "${var.env}-sm-portal-api"
    ClusterName = aws_ecs_cluster.ecs_cluster.name
  }
}

resource "aws_cloudwatch_event_rule" "ecs_memory_alarm_rule" {
  name          = "${var.env}-ecs-memory-alarm-rule"
  description   = "Trigger Lambda when ECS service memory alarm state changes to ALARM"
  event_pattern = <<PATTERN
{
  "source": ["aws.cloudwatch"],
  "detail-type": ["CloudWatch Alarm State Change"],
  "resources": ["${aws_cloudwatch_metric_alarm.ecs_memory_alarm.arn}"],
  "detail": {
    "state": {
      "value": ["ALARM"]
    }
  }
}

PATTERN
}

resource "aws_cloudwatch_event_target" "ecs_service_update_lambda" {
  rule      = aws_cloudwatch_event_rule.ecs_memory_alarm_rule.name
  target_id = "lambda"
  arn       = aws_lambda_function.ecs_service_update_lambda.arn
}

resource "aws_lambda_permission" "allow_event_rule_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_service_update_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_memory_alarm_rule.arn
}

// Comms send whatsapp lambda
resource "aws_lambda_function" "comms_send_whatsapp" {
  function_name = "${var.env}-atribo-comms-send-whatsApp-lambda"
  role          = aws_iam_role.atribo_comms_send_whatsApp_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-comms-send-whatsapp-lambda:${local.sm_comms_send_whatsapp_lambda_version}"
  timeout       = 40
  environment {
    variables = {
      env                     = var.env
      WhatsAppAccountSid      = aws_ssm_parameter.whatsapp_account_sid.value
      WhatsAppAuthToken       = aws_ssm_parameter.whatsapp_auth_token.value
      WhatsAppFromPhoneNumber = aws_ssm_parameter.whatsapp_from_phone_number.value
    }
  }
}

// Comms send email lambda
resource "aws_lambda_function" "comms_send_email" {
  function_name = "${var.env}-atribo-comms-send-email-lambda"
  role          = aws_iam_role.atribo_comms_send_email_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-comms-send-email-lambda:${local.sm_comms_send_email_lambda_version}"
  timeout       = 40
  environment {
    variables = {
      env                 = var.env
      SESConfigurationSet = aws_ses_configuration_set.Comms_Send_Email.name
    }
  }
}

// Comms send sms lambda
resource "aws_lambda_function" "comms_send_sms" {
  function_name = "${var.env}-atribo-comms-send-sms-lambda"
  role          = aws_iam_role.atribo_comms_send_sms_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-comms-send-sms-lambda:${local.sm_comms_send_sms_lambda_version}"
  timeout       = 40
  environment {
    variables = {
      env = var.env
    }
  }
  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

// DynamoDB data retrieval lambda
resource "aws_lambda_function" "dynamodb_data_retrieval_lambda" {
  function_name = "${var.env}-dynamodb-data-retrieval-lambda"
  role          = aws_iam_role.dynamodb_data_retrieval_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-dynamodb-data-retrieval-lambda:${local.sm_dynamodb_data_retrieval_lambda}"
  timeout       = 40
  environment {
    variables = {
      env = var.env
    }
  }
}


#communication history lambda
resource "aws_lambda_function" "comms_history_lambda" {
  function_name = "${var.env}-comms-history"
  role          = aws_iam_role.comms_history_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/comms-history-lambda:${local.comms_history_lambda_version}"
  timeout       = 40

  memory_size = 512

  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

#AtriboCommunicationSchedulerLambda
resource "aws_lambda_function" "communication_scheduler_lambda" {
  function_name = "${var.env}-communication-scheduler-lambda"
  role          = aws_iam_role.communication_scheduler_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/communication-scheduler-lambda:${local.communication_scheduler_lambda_version}"
  timeout       = 40
  environment {
    variables = {
      env = var.env
    }
  }
}


#AtriboCommsTemplatingLambda
resource "aws_lambda_function" "comms-templating-lambda" {
  function_name = "${var.env}-comms-templating-lambda"
  role          = aws_iam_role.atribo_comms_templating_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-comms-templating-lambda:${local.sm_comms_templating_lambda_version}"
  timeout       = 40
  environment {
    variables = {
      env = var.env
    }
  }
}


# sms response handler lambda
# resource "aws_lambda_function" "sms_response_handler_lambda" {
#   function_name = "${var.env}-sms-response-handler-lambda"
#   role          = aws_iam_role.sms_response_handler_lambda_role.arn
#   package_type  = "Image"
#   image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sms-response-handler-lambda:${local.sms_response_handler_lambda_version}"
#   timeout       = 40
#   environment {
#     variables = {
#       userPoolId = "${module.api.cognito_arn}"
#     }
#   }
# }
# resource "aws_lambda_permission" "with_sns" {
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.sms_response_handler_lambda.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.sns_sms_response_topic.arn
# }

/* Atribo Registration Lambda
resource "aws_lambda_function" "atribo_registration_lambda" {
  function_name = "atribo-${var.env}-registration"
  role          = aws_iam_role.atribo_registration_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-atribo-registration-lambda:${local.atribo_registration_lambda_version}"
  timeout = 40
  environment{
    variables ={
      env = var.env
    }
  }
}*/
resource "aws_lambda_function" "sm_pdf_processing_lambda" {
  function_name = "${var.env}-sm-pdf-processing-lambda"
  role          = aws_iam_role.sm_pdf_processing_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-pdf-processing-lambda:${local.sm_pdf_processing_lambda_version}"
  timeout       = 600
  memory_size   = 1024
  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }
  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

}

#ATRIBO-11112 setup for capturing email delivery results

resource "aws_lambda_function" "comms_store_delivery_event_lambda" {
  function_name = "${var.env}-sm-comms-delivery-data-lambda"
  role          = aws_iam_role.comms_store_delivery_event_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-comms-delivery-data-lambda:${local.comms_store_delivery_event_verion}"
  timeout       = 600
  memory_size   = 1024
  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }


}
resource "aws_lambda_permission" "sns_invoke_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.comms_store_delivery_event_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ses_delivery_events.arn
}

resource "aws_scheduler_schedule" "CognitoPreAuth_Lambda_schedule" {
  name       = "${var.env}-preAuth-Lambda-update-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0/5 * * * ? *)"

  target {
    arn      = aws_lambda_function.Cognito_Pre_Auth.arn
    role_arn = aws_iam_role.eventbridge_invoke_lambda_role.arn
    input    = <<EOT
{
    "version": "1",
    "region": "eu-west-2",
    "userPoolId": "eu-west-2_8XVE45sSD",
    "userName": "test",
    "callerContext": {
        "awsSdkVersion": "aws-sdk-js-3.45.0",
        "clientId": "63e6a5emisd8ecpdf3c0io401n"
    },
    "triggerSource": "PreSignUp_SignUp",
    "request": {
        "userAttributes": {},
        "validationData": {
            "adminIgnoreOtpValidation":"true"
        }
    },
    "response": {}
}
 EOT

  }
}

#Project App Lambda 
## A lambda function in product that creates a fargate container task

data "archive_file" "project_app_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambda/project-app-lambda"
  output_path = "${path.module}/src/lambda/project-app-lambda.zip"
}

resource "aws_lambda_function" "project_app_lambda" {
  function_name = "${var.env}-project-app-lambda"
  role          = aws_iam_role.project_app_lambda_role.arn
  handler       = "project-app-lambda.lambda_handler"
  runtime       = "python3.8"
  source_code_hash = data.archive_file.project_app_lambda_zip.output_base64sha256
  filename      = data.archive_file.project_app_lambda_zip.output_path
   
  environment {
    variables = {
      cluster_name = aws_ecs_cluster.fargate_cluster.name
      subnet_id = join(",", module.vpc.private_subnets[*])
      security_group_id = aws_security_group.ecs_sg.id
      family = "${var.env}-project-apps"
      log_group = aws_cloudwatch_log_group.app_log_group.name
      region = var.region
      iam_role = aws_iam_role.ecs_role.arn
      EVENT_DETAIL = "event.detail",
      image_id = "",
      cpu = "256",
      memory = "512"
    }
  }
  depends_on = [aws_ecs_cluster.fargate_cluster]
}

resource "aws_lambda_function" "email_receiving_lambda" {
  function_name = "${var.env}-email-receiving-lambda"
  role          = aws_iam_role.email_receiving_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-email-receiving-lambda:${local.sm_email_receiving_lambda_version}"
  timeout       = 40
  memory_size = 512
    vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment {
    variables = {
      env = var.env
    }
  } 
}
resource "aws_lambda_function" "sms_receiving_lambda" {
  function_name = "${var.env}-sms-receiving-lambda"
  role          = aws_iam_role.sms_receiving_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-sms-receiving-lambda:${local.sm_sms_receiving_lambda_version}"
  timeout       = 40
  memory_size = 512
    vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment {
    variables = {
      env = var.env
    }
  } 
}

resource "aws_lambda_permission" "sns_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sms_receiving_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sms_receiving_notification.arn
}

resource "aws_lambda_permission" "lambda_permission" {
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.email_receiving_lambda.function_name
  principal      = "ses.amazonaws.com"
  source_account = "${local.account_id}"
}


resource "aws_lambda_permission" "email_receiving" {
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.email_receiving_lambda.function_name
  principal      = "ses.amazonaws.com"
  source_account = "${local.account_id}"
  source_arn = aws_ses_receipt_rule.email_receipt_rule.arn
  depends_on = [
    aws_lambda_permission.lambda_permission
  ]
}
resource "aws_lambda_permission" "sns_email_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_receiving_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.email_receiving_notification.arn
}

resource "aws_lambda_function" "sns_sms_delivery_logs_lambda" {
  function_name = "${var.env}-sns-sms-delivery-logs-lambda"
  role          = aws_iam_role.sns_sms_delivery_logs_lambda_role.arn
  package_type  = "Image"
  image_uri     = "436186951226.dkr.ecr.${var.region}.amazonaws.com/sm-comms-delivery-data-lambda:${local.sns_sms_delivery_logs_lambda_version}"
  timeout       = 600
  memory_size   = 1024
  environment {
    variables = {
      env    = var.env
      domain = var.domain
    }
  }

}

resource "aws_lambda_permission" "sns_sms_failure_delivery_logs_permission" {
  statement_id  = "AllowExecutionFromCloudwatch_failure_logs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_sms_delivery_logs_lambda.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.sns_sms_failure_delivery_logs.arn}:*"
  
}
resource "aws_lambda_permission" "sns_sms_success_delivery_logs_permission" {
  statement_id  = "AllowExecutionFromCloudwatch_success_logs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_sms_delivery_logs_lambda.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.sns_sms_success_delivery_logs.arn}:*"

}

resource "aws_cloudwatch_log_subscription_filter" "sns_sms_failure_delivery_logs_sub" {
  depends_on = [aws_lambda_permission.sns_sms_failure_delivery_logs_permission]
  name            = "failure-events-trigger"
  log_group_name  = aws_cloudwatch_log_group.sns_sms_failure_delivery_logs.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.sns_sms_delivery_logs_lambda.arn
  
}


resource "aws_cloudwatch_log_subscription_filter" "sns_sms_success_delivery_logs_sub" {
  depends_on = [aws_lambda_permission.sns_sms_success_delivery_logs_permission]
  name            = "success-sms-event"
  log_group_name  = aws_cloudwatch_log_group.sns_sms_success_delivery_logs.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.sns_sms_delivery_logs_lambda.arn
 
}

resource "aws_cloudwatch_log_group" "sns_sms_success_delivery_logs" {
  name              = "sns/${var.region}/${local.account_id}/DirectPublishToPhoneNumber"
}

resource "aws_cloudwatch_log_group" "sns_sms_failure_delivery_logs" {
  name              = "sns/${var.region}/${local.account_id}/DirectPublishToPhoneNumber/Failure" 
}

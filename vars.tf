variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/20"
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.2.0/24", "10.0.4.0/24"]
}

variable "ecs_autoscale_min" {
  type    = number
  default = 1
}

variable "ecs_autoscale_max" {
  type    = number
  default = 2
}

variable "ecs_autoscale_desired" {
  type    = number
  default = 1
}

variable "health_check_path" {
  type        = string
  description = "Health check path for the default target group"
  default     = "/healthcheck"
}

variable "domain" {
  type = string
}

variable "survey-form-validator-lambda_version" {
  type = string
  default = ""
}

variable "size" {
  type = string
}

variable "branch" {
  type = string
}

variable "site_app_name" {
  type    = string
  default = "enhanced-prototype"
}

variable "dns_name" {
  type    = string
  default = "squidex"
}

variable "config_template" {
  type = string

}
variable "project_version" {
  type = list(object({
    project = string
    version     = string
  }))
  description = "List of projects and version"
  default = []
}

variable "google_analytics_api_key" {
  type = string
}

variable "google_recaptcha_site_key" {
  type = string
}

variable "google_recaptcha_secret_key" {
  type = string
}

variable "backup_enabled" {
  type    = string
  default = "off"
}

variable "backup_retention" {
  type    = string
  default = "14"
}

variable "backup_frequency" {
  type        = string
  description = "Could be daily, weekly, monthly"
  default     = "daily"
}

variable "backup_region" {
  type    = string
  default = "eu-west-1"
}

variable "continuous_backup_enabled" {
  type    = string
  default = "off"
}

variable "continuous_backup_retention" {
  type    = string
  default = "7"
}

variable "dev_vpn_enabled" {
  type    = string
  default = "off"
}

# one version for all atribo
variable "atribo_version" {
  type = string
  default = ""

}

variable "TFC_CONFIGURATION_VERSION_GIT_TAG" {
  type = string
  default = ""
}

variable "config_auto_update" {
  type    = string
  default = "false"
}
variable "name" {  # project name
  type    = string
  default = ""
}




locals {
   
  #assign git  tag value to these 4 variable if not defined at TFC workspace
  
  final_atribo_version                       = var.atribo_version != "" ? var.atribo_version : var.TFC_CONFIGURATION_VERSION_GIT_TAG
  # final_website_version                      = var.website_version != "" ? var.website_version : var.TFC_CONFIGURATION_VERSION_GIT_TAG
  # final_creator_version                      = var.creator_version != "" ? var.creator_version : var.TFC_CONFIGURATION_VERSION_GIT_TAG
  final_survey-form-validator-lambda_version = var.survey-form-validator-lambda_version != "" ? var.survey-form-validator-lambda_version : var.TFC_CONFIGURATION_VERSION_GIT_TAG

  # website_version                      = local.final_website_version
  # creator_version                      = local.final_creator_version
  survey-form-validator-lambda_version = local.final_survey-form-validator-lambda_version

  config-ui_version                          = local.final_atribo_version
  dms_version                                = local.final_atribo_version
  email-service_version                      = local.final_atribo_version
  config-service_version                     = local.final_atribo_version
  atribo-userui_version                      = local.final_atribo_version
  atribo-userapi_version                     = local.final_atribo_version
  sm-bulkupdatesvc_version                   = local.final_atribo_version
  sm-data-api_version                        = local.final_atribo_version
  sm-extract-service_version                 = local.final_atribo_version
  sm-portal-api_version                      = local.final_atribo_version
  sm-portal-ui_version                       = local.final_atribo_version
  dynamodb-sh-lambda_version                 = local.final_atribo_version
  dynamodb-ssm-lambda_version                = local.final_atribo_version
  db-seeding-portal-lambda_version           = local.final_atribo_version
  atribo-identity_version                    = local.final_atribo_version
  db-seeding-dms-lambda_version              = local.final_atribo_version
  db-seeding-identity-lambda_version         = local.final_atribo_version
  dms-notification-lambda_version            = local.final_atribo_version
  atribo-serverless-identity_version         = local.final_atribo_version
  cognito-verify-auth-lambda_version         = local.final_atribo_version
  cognito-pre-authentication-lambda_version  = local.final_atribo_version
  audit-lambda_version                       = local.final_atribo_version
  cognito-post-authentication-lambda_version = local.final_atribo_version
  sm-dashboard-service_version               = local.final_atribo_version
  sm_setupuser_lambda_version                = local.final_atribo_version
  sm_comms_send_email_lambda_version         = local.final_atribo_version
  sms_response_handler_lambda_version        = local.final_atribo_version
  communication_scheduler_lambda_version     = local.final_atribo_version
  sm_comms_templating_lambda_version         = local.final_atribo_version
  comms_history_lambda_version               = local.final_atribo_version
  sm_dynamodb_data_retrieval_lambda          = local.final_atribo_version
  sm_comms_send_sms_lambda_version           = local.final_atribo_version
  sm_comms_send_whatsapp_lambda_version      = local.final_atribo_version
  sm-statustransition-service_version        = local.final_atribo_version
  sm_useridentifier_lambda_version           = local.final_atribo_version
  sm_messagequeue_lambda_version             = local.final_atribo_version
  cognito-create-auth-lambda_version         = local.final_atribo_version
  cognito-define-auth-lambda_version         = local.final_atribo_version
  cognito-pre-sign-up-lambda_version         = local.final_atribo_version
  sm_pdf_processing_lambda_version           = local.final_atribo_version
  atribo_registration_lambda_version         = local.final_atribo_version
  comms_store_delivery_event_verion          = local.final_atribo_version
  sm_email_receiving_lambda_version          = local.final_atribo_version
  sm_sms_receiving_lambda_version            = local.final_atribo_version
  sns_sms_delivery_logs_lambda_version       = local.final_atribo_version
}


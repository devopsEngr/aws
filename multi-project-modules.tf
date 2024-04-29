data "aws_route53_zone" "public" {
  name         = var.domain
  private_zone = false
}

locals {
  reserved_memory ={
  tiny  = 128
  small  = 256
  medium = 512
  large  = 1024
  }
}

module "atribo-identity" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "atribo-identity"
  image_version          = local.atribo-identity_version
  repo_id                = "CoreWebsite"
  listener_http_arn      = aws_alb_listener.external_http_listener.arn
  listener_https_arn     = aws_lb_listener.external_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 1
  http_redirect_disabled = 0
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 0
  ga_external_enabled    = 1
  ga_internal_disabled   = 1
  ga_external_disabled   = 0
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

  health_check_grace_period_seconds = 300
  depends_on = [
    
    
  
    aws_lb_listener.external_https_listener,
    aws_globalaccelerator_accelerator.aws-ga-external,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group,
    module.config-service
  ]
}

module "atribo-userapi" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "atribo-userapi"
  image_version          = local.atribo-userapi_version
  repo_id                = "CoreWebsite"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 1
  api_gateway_disabled   = 0
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

    
     
  depends_on = [
   
   
  
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "atribo-userui" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  workspaceId            = aws_ssm_parameter.common_DefaultWorkspaceId.value
  service_name           = "atribo-userui"
  image_version          = local.atribo-userui_version
  repo_id                = "CoreWebsite"
  listener_http_arn      = aws_alb_listener.external_http_listener.arn
  listener_https_arn     = aws_lb_listener.external_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  domain                 = var.domain
  http_redirect_enabled  = 1
  http_redirect_disabled = 0
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 1
  ga_external_enabled    = 1
  ga_internal_disabled   = 0
  ga_external_disabled   = 0
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

   
    
  depends_on = [
    
    
  
    aws_lb_listener.external_https_listener,
    aws_globalaccelerator_accelerator.aws-ga-external,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "config-service" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "config-service"
  image_version          = local.config-service_version
  repo_id                = "ConfigurationManagement"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 1
  api_gateway_disabled   = 0
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

  wait_for_steady_state  = true  
     
  depends_on = [

    aws_lambda_function.DynamoDBSnapshotSchemaManager,
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    # aws_s3_object.core-sitecontents-config-file,
    # aws_s3_object.sm-extract-svc-config-file,
    # aws_s3_object.um-sitecontents-config-file,
    # aws_s3_object.workspace_configuration_file,
    # aws_s3_object.applicant-hub-appsettings-file,
    module.api.cognito_id,
    module.static_site,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "config-ui" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "config-ui"
  image_version          = local.config-ui_version
  repo_id                = "ConfigurationManagement"
  listener_http_arn      = aws_alb_listener.external_http_listener.arn
  listener_https_arn     = aws_lb_listener.external_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 1
  http_redirect_disabled = 0
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 1
  ga_external_enabled    = 1
  ga_internal_disabled   = 0
  ga_external_disabled   = 0
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

    
     
  depends_on = [
    
    
  
    aws_lb_listener.external_https_listener,
    aws_globalaccelerator_accelerator.aws-ga-external,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "dms" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "dms"
  image_version          = local.dms_version
  repo_id                = "DocumentManagement"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 1
  api_gateway_disabled   = 0
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

  health_check_grace_period_seconds = 300
    
     
  depends_on = [
   
    
  
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "email-service" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "email-service"
  image_version          = local.email-service_version
  repo_id                = "CoreWebsite"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

    
     
  depends_on = [

    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}


module "sm-dashboard-service" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "sm-dashboard-service"
  image_version          = local.sm-dashboard-service_version
  repo_id                = "SubmissionManagement"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

    
     
  depends_on = [
     
    
  
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "sm-statustransition-service" { 
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "sm-statustransition-service"
  image_version          = local.sm-statustransition-service_version
  repo_id                = "SubmissionManagement"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

    
     
  memoryReservation      = local.reserved_memory[var.size]

  depends_on = [
    
    
  
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}


module "sm-bulkupdatesvc" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "sm-bulkupdatesvc"
  image_version          = local.sm-bulkupdatesvc_version
  repo_id                = "SubmissionManagement"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id
  
  memoryReservation      = local.reserved_memory[var.size]
  
  depends_on = [
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "sm-data-api" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "sm-data-api"
  image_version          = local.sm-data-api_version
  repo_id                = "SubmissionManagement"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 1
  api_gateway_disabled   = 0
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

     
  depends_on = [
    
    
  
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "sm-extract-service" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "sm-extract-service"
  image_version          = local.sm-extract-service_version
  repo_id                = "SubmissionManagement"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

  memoryReservation      = local.reserved_memory[var.size]

    
     
  depends_on = [
    
    
  
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "sm-portal-api" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  service_name           = "sm-portal-api"
  image_version          = local.sm-portal-api_version
  repo_id                = "SubmissionManagement"
  listener_http_arn      = aws_alb_listener.internal_http_listener.arn
  listener_https_arn     = aws_lb_listener.internal_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 0
  http_redirect_disabled = 1
  api_gateway_enabled    = 1
  api_gateway_disabled   = 0
  ga_internal_enabled    = 1
  ga_external_enabled    = 0
  ga_internal_disabled   = 0
  ga_external_disabled   = 1
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

    
     
  memoryReservation      = local.reserved_memory[var.size]

  health_check_grace_period_seconds = 300
  depends_on = [
    
    
  
    aws_lambda_function.DynamoDBSnapshotSchemaManager,
    module.config-service,
    aws_globalaccelerator_accelerator.aws-ga-internal,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}

module "sm-portal-ui" {
  region                 = var.region
  source                 = "./modules/ecs"
  branch                 = var.branch
  env                    = var.env
  workspaceId            = aws_ssm_parameter.common_DefaultWorkspaceId.value
  service_name           = "sm-portal-ui"
  image_version          = local.sm-portal-ui_version
  repo_id                = "SubmissionManagement"
  listener_http_arn      = aws_alb_listener.external_http_listener.arn
  listener_https_arn     = aws_lb_listener.external_https_listener.arn
  internal_domain_zone   = aws_route53_zone.internal.zone_id
  external_domain_zone   = data.aws_route53_zone.public.zone_id
  domain                 = var.domain
  http_redirect_enabled  = 1
  http_redirect_disabled = 0
  api_gateway_enabled    = 0
  api_gateway_disabled   = 1
  ga_internal_enabled    = 1
  ga_external_enabled    = 1
  ga_internal_disabled   = 0
  ga_external_disabled   = 0
  vpc_id                 = module.vpc.vpc_id
  alb_internal           = aws_lb.alb_internal.arn
  alb_external           = aws_lb.alb_external.arn
  ga_external_dns_name   = aws_globalaccelerator_accelerator.aws-ga-external.dns_name
  ga_external_zone_id    = aws_globalaccelerator_accelerator.aws-ga-external.hosted_zone_id
  ga_internal_dns_name   = aws_globalaccelerator_accelerator.aws-ga-internal.dns_name
  ga_internal_zone_id    = aws_globalaccelerator_accelerator.aws-ga-internal.hosted_zone_id
  ecs_role               = aws_iam_role.ecs_service_role.arn
  cluster_name           = aws_ecs_cluster.ecs_cluster.name
  vpc-link               = aws_api_gateway_vpc_link.this.id
  dockerfile             = "dockerfile"
  cert_arn               = aws_acm_certificate_validation.example.certificate_arn
  test_validation        = aws_acm_certificate_validation.example.id

   
    
  memoryReservation      = local.reserved_memory[var.size]

  depends_on = [
    
    
  
    aws_lb_listener.external_https_listener,
    aws_globalaccelerator_accelerator.aws-ga-external,
    aws_ecs_cluster.ecs_cluster,
    aws_autoscaling_group.ecs_asg,
    aws_iam_role.ecs_service_role,
    aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
    aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
    aws_iam_policy.ecs_service_role_permissions,
    aws_cloudwatch_log_group.app_log_group
  ]
}
#Squidex
module "squidex-deploy" {
    source = "./modules/squidex"
    cluster_name         = aws_ecs_cluster.ecs_cluster.name
    ecs_role             = aws_iam_role.ecs_service_role.arn
    alb_subnets          = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]
    subnets              = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    vpc_id               = module.vpc.vpc_id
    internal_domain_zone = aws_route53_zone.internal.zone_id
    external_domain_zone = data.aws_route53_zone.public.zone_id
    domain               = var.domain
    dns_name             = var.dns_name
    region               = var.region
    env                  = var.env
    backup_enabled       = var.backup_enabled
    sg_ecs               = aws_security_group.ecs_sg.id
    certificate          = aws_acm_certificate.example.arn
    depends_on = [
      aws_instance.mongodb,
      aws_security_group.ecs_sg,
      aws_ecs_cluster.ecs_cluster,
      aws_autoscaling_group.ecs_asg,
      aws_iam_role.ecs_service_role,
      aws_iam_role_policy_attachment.ecs_service_role_policy_attachment,
      aws_iam_policy_attachment.ecs_instance_role_policy_attachment,
      aws_iam_policy.ecs_service_role_permissions,
      aws_iam_policy.ecs_role_permissions,
      module.vpc,
      module.atribo-identity,
      module.atribo-userapi,
      module.atribo-userui,
      module.config-service,
      module.config-ui,
      module.dms,
      module.email-service,
      module.sm-bulkupdatesvc,
      module.sm-data-api,
      module.sm-extract-service,
      module.sm-portal-api,
      module.sm-portal-ui
    ]
}


module "static_site" {
    source = "./modules/static_site"

    env = var.env
    region = var.region
    domain = var.domain
    project_version = var.project_version
    dns_name = var.dns_name
    config_bucket = aws_s3_bucket.atribo-config-bucket.id
    certificate = aws_acm_certificate.example.arn
    google_analytics_api_key = var.google_analytics_api_key
    google_recaptcha_site_key = var.google_recaptcha_site_key
    google_recaptcha_secret_key = var.google_recaptcha_secret_key
    providers = {
      aws = aws
      aws.global = aws.global
    }
    api_gate = {
    for key, api in module.api : key => "squidex-api-${key}.${var.domain}" # key is project name
    }
    cognito_pool_id = {
     for project in var.project_version : project.project => module.api[project.project].cognito_id
    }
  

    squidex_uri = "https://${var.dns_name}.${var.domain}"
   
}
locals {
  projectList = {
    for pv in var.project_version : pv.project => {
      project_name = "${pv.project}"
    }
  }
}


module "api" {
  source = "./modules/api"
  
  for_each = local.projectList
  env    = var.env
 
  balancer_uri           = "${var.dns_name}.${var.domain}"
  domain                 = "${var.domain}"
  dns_name               = "squidex-api-${each.value.project_name}"
  sm_api_host            = "sm-portal-api.${var.domain}"
  app                     = each.value.project_name
  subnets                = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
  vpc_id                 = module.vpc.vpc_id
  internal_alb_arn       = aws_lb.alb_internal.id
  certificate_validation = aws_acm_certificate_validation.example.certificate_arn
  user_identifier_lambda_arn = aws_lambda_function.User_Identifier.invoke_arn
 
  lambdas = {
   
    post_confirm = module.lambda.identity_lambda
  }
  cognito = {
    create_auth_challenge          = aws_lambda_function.Cognito_Create_Auth.arn
    define_auth_challenge          = aws_lambda_function.Cognito_Define_Auth.arn
    pre_sign_up                    = aws_lambda_function.Cognito_Pre_Sign_Up.arn
    verify_auth_challenge_response = aws_lambda_function.Cognito_Verify_Auth.arn
    pre_authentication             = aws_lambda_function.Cognito_Pre_Auth.arn
    post_authentication            = aws_lambda_function.Cognito_Post_Auth.arn
  }
  depends_on = [
    aws_lb.alb_internal,
    aws_lb_target_group.alb-tg,
    aws_alb_listener.internal_http_listener,
    aws_lambda_function.Cognito_Create_Auth,
    aws_lambda_function.Cognito_Define_Auth,
    aws_lambda_function.Cognito_Pre_Sign_Up,
    aws_lambda_function.Cognito_Verify_Auth,
    module.vpc
  ]
}

module "lambda" {
    source = "./modules/lambda"
    region = var.region
    domain = var.domain
    env = var.env
    # survey_env_vars = {
    #         ContentApiUrl = "https://squidex-dev.atribodev.com"
    #         PortalApiUrl = "https://n9hibrz0cl.execute-api.ap-southeast-2.amazonaws.com/test/sm-portal-api"
    # }
    # environment = var.env
    image_version = local.atribo-serverless-identity_version
    repo_url = "436186951226.dkr.ecr.${var.region}.amazonaws.com"
    vpc_id = module.vpc.vpc_id
    private_subnets = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    depends_on = [
      module.vpc
    ]
}

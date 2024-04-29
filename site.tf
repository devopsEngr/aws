# resource "aws_s3_bucket_website_configuration" "engagement_hub" {
#   bucket = aws_s3_bucket.engagement_hub.bucket

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "error.html"
#   }
# }

resource "aws_cloudfront_response_headers_policy" "reach_headers_policy" {
  name = "${var.env}-security-headers-policy"
  security_headers_config {
    content_type_options {
      override = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override = true
    }
    strict_transport_security {
      access_control_max_age_sec = "31536000"
      include_subdomains = true
      preload = true
      override = true
    }
    content_security_policy {
      # content_security_policy = "frame-ancestors 'none'; default-src 'none'; img-src 'self'; script-src 'self'; style-src 'self'; object-src 'none'"
      content_security_policy = "default-src 'self' data: 'unsafe-eval' 'unsafe-inline' https://cognito-idp.${var.region}.amazonaws.com/ https://*.s3.${var.region}.amazonaws.com/ https://*.google-analytics.com/ https://www.google-analytics.com/ https://www.googletagmanager.com/gtag/ https://www.google.com/recaptcha/ https://www.gstatic.com/recaptcha/ https://*.${var.domain} https://cloud.squidex.io/scripts/ https://www.googletagmanager.com/ https://connect.facebook.net/ https://www.facebook.com/ https://*.facebook.com/ https://static.zdassets.com https://ekr.zdassets.com https://ekr.zendesk.com https://*.zendesk.com https://*.zopim.com wss://*.zopim.com wss://*.zendesk.com https://zendesk-eu.my.sentry.io https://v2assets.zopim.io; object-src 'self' data:; frame-ancestors 'self' https://*.thereachagency.com https://*.atribo.io https://*.${var.domain}; font-src 'self' data: 'unsafe-inline' https://cdnjs.cloudflare.com https://fonts.googleapis.com https://fonts.gstatic.com https://*.${var.domain} https://static.thereachagency.com; style-src 'self' data: 'unsafe-inline' https://fonts.googleapis.com https://*.${var.domain} https://static.thereachagency.com https://cdnjs.cloudflare.com https://www.google.com/maps/;"
      override = true
    }
  }
  custom_headers_config {
    items {
      header   = "Expect-CT"
      override = true
      value    = "enforce, max-age=30"
    }

    items {
      header   = "Permissions-Policy"
      override = true
      value    = "geolocation=self, midi=self, sync-xhr=self, microphone=self, camera=self, magnetometer=self, gyroscope=self, fullscreen=self, payment=self"
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "engagement_hub" {
}

resource "aws_cloudfront_origin_access_identity" "survey_creator" {
}

# resource "aws_cloudfront_origin_access_control" "engagement_hub_oac" {
# 	name                              = "${var.env}_engagement_hub_oac"
# 	description                       = ""
# 	origin_access_control_origin_type = "s3"
# 	signing_behavior                  = "always"
# 	signing_protocol                  = "sigv4"
# }
#
# resource "aws_cloudfront_origin_access_control" "survey_creator_oac" {
# 	name                              = "${var.env}_survey_creator_oac"
# 	description                       = ""
# 	origin_access_control_origin_type = "s3"
# 	signing_behavior                  = "always"
# 	signing_protocol                  = "sigv4"
# }

# resource "aws_cloudfront_cache_policy" "auth-no-cache" {
#  for_each = local.project_configurations
#   name        = "${var.env}-${each.key}-squidex-auth-no-cache"
#   comment     = "Allow auth header"
#   default_ttl = 0
#   max_ttl     = 1
#   min_ttl     = 0
#   parameters_in_cache_key_and_forwarded_to_origin {
#     cookies_config {
#       cookie_behavior = "all"
#     }
#     headers_config {
#       header_behavior = "whitelist"
#       headers {
#         items = ["Authorization"]
#       }
#     }
#     query_strings_config {
#       query_string_behavior = "all"
#     }
#   }
# }
locals {
  project_configurations = length(var.project_version) > 0 ? {
    for pv in var.project_version : pv.project => {
      domain  = "${pv.project}.${var.domain}"
      version = pv.version
    }
  } : {}
}
resource "aws_cloudfront_distribution" "engagement_hub_subdomains" {
 for_each = local.project_configurations

  default_root_object  = "index.html"
  aliases = ["www.${each.value.domain}", "${each.value.domain}"]
  enabled = true
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code = 404
    response_code  = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code = 403
    response_code  = 200
    response_page_path = "/index.html"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "engagementHubOriginS3"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.reach_headers_policy.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 3600

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.*.arn[length(aws_cloudfront_function.redirect.*.arn) - 1]
    }
}

ordered_cache_behavior {
  path_pattern     = "/api/*"
  allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods   = ["GET", "HEAD"]
  target_origin_id = "apiGateway"
  # cache_policy_id = aws_cloudfront_cache_policy.auth-no-cache.id
  response_headers_policy_id = aws_cloudfront_response_headers_policy.reach_headers_policy.id
  viewer_protocol_policy = "redirect-to-https"
      forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
      headers      = ["Authorization"]
    }
}
ordered_cache_behavior {
  path_pattern     = "/sm-portal-api/*"
  allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods   = ["GET", "HEAD"]
  target_origin_id = "apiGateway"
  response_headers_policy_id = aws_cloudfront_response_headers_policy.reach_headers_policy.id
  # cache_policy_id = aws_cloudfront_cache_policy.auth-no-cache.id
  viewer_protocol_policy = "redirect-to-https"
      forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
      headers      = ["Authorization", "token"]
    }
}

ordered_cache_behavior {
  path_pattern     = "/config-service/*"
  allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods   = ["GET", "HEAD"]
  target_origin_id = "apiGateway"
  response_headers_policy_id = aws_cloudfront_response_headers_policy.reach_headers_policy.id
  # cache_policy_id = aws_cloudfront_cache_policy.auth-no-cache.id
  viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = true
        cookies {
          forward = "none"
        }
    }
}

ordered_cache_behavior {
  path_pattern     = "/user-identifier/*"
  allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods   = ["GET", "HEAD"]
  target_origin_id = "apiGateway"
  # cache_policy_id = aws_cloudfront_cache_policy.auth-no-cache.id
  response_headers_policy_id = aws_cloudfront_response_headers_policy.reach_headers_policy.id
  viewer_protocol_policy = "redirect-to-https"
      forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
      headers      = ["Authorization"]
    }
}
ordered_cache_behavior {
  path_pattern     = "/creator/config-service/*"
  allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods   = ["GET", "HEAD"]
  target_origin_id = "apiGateway"
  response_headers_policy_id = aws_cloudfront_response_headers_policy.reach_headers_policy.id
  viewer_protocol_policy = "redirect-to-https"
      forwarded_values {
        query_string = true
          cookies {
            forward = "none"
      }
    }
}

ordered_cache_behavior {
  path_pattern     = "/creator/*"
  allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods   = ["GET", "HEAD"]
  target_origin_id = "surveyCreatorOriginS3"
  response_headers_policy_id = aws_cloudfront_response_headers_policy.reach_headers_policy.id
  viewer_protocol_policy = "redirect-to-https"
      forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.index.arn
    }
}

  origin {
    domain_name = aws_s3_bucket.engagement_hub.bucket_regional_domain_name
    origin_id = "engagementHubOriginS3"
    origin_path = "/website_${each.value.version}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.engagement_hub.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_s3_bucket.survey_creator.bucket_regional_domain_name
    origin_id = "surveyCreatorOriginS3"
    origin_path = "/creator_${each.value.version}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.survey_creator.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name =  var.api_gate[each.key]
    
    origin_id = "apiGateway"
	  custom_origin_config {
		  http_port              = 80
		  https_port             = 443
		  origin_protocol_policy = "https-only"
		  origin_ssl_protocols   = ["TLSv1.2"]
	  }
  }
  viewer_certificate {

   acm_certificate_arn=module.acm_certificate_subdomain[each.key].certificate_arn
    
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  depends_on = [
   
    module.acm_certificate_subdomain
  ]
  tags = {
    Name = "${each.value.domain}-engagement_hub"
    Env = var.env
  }

}
resource "aws_cloudfront_function" "index" {
  name    = "${data.aws_region.current.name}-rootIndex-${var.env}"
  runtime = "cloudfront-js-1.0"
  comment = "rewrite root request to the index.html"
  publish = true
  code    = file("${path.module}/rewrite.js")
 lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

resource "aws_cloudfront_function" "redirect" {
  name    = "${data.aws_region.current.name}-redirect-${var.env}"
  runtime = "cloudfront-js-1.0"
  comment = "redirect custom name to /page/registration"
  publish = true
  code    = templatefile(
    "${path.module}/redirect.js.tpl",
    {
      domain = var.domain
    }
  )
 lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

# Create web-client for cognito
resource "aws_cognito_user_pool_client" "web_client" {
 for_each           = var.cognito_pool_id

  name               = "${var.env}-site-${each.key}"
  user_pool_id       = each.value
  access_token_validity                = 1 # hours
  refresh_token_validity               = 30 # days
  id_token_validity                    = 1 # hours
  generate_secret                      = false
  explicit_auth_flows                  = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
#    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
}

data "aws_region" "current" {
  
}

data "template_file" "site_parameter_value" {
  template = file("${path.module}/config.json.tftpl")
  vars = {

      region = var.region
      domain = var.domain
      google_analytics_api_key = coalesce(var.google_analytics_api_key, "G-RFTYP7NVB8")
      google_recaptcha_site_key = coalesce(var.google_recaptcha_site_key, "6LfiK88iAAAAAL9Sxo-SCFFxAUz73lVVUlM-vp1T")
      google_recaptcha_secret_key = coalesce(var.google_recaptcha_secret_key, "6LfiK88iAAAAABrt7iSgM1o0Hjkl-SWtm870q8jw")
      env = var.env
      app_uri = var.squidex_uri
       
      dns_name = var.dns_name
project_configurations   = jsonencode([
      for project_key, project_value in local.project_configurations : {
        "projectName" = project_key,
        
        "domain"      = project_value.domain,
        "cognito"     = {
          "auth" = {
          "userPoolId"          = var.cognito_pool_id[project_key],
            "userPoolWebClientId" = aws_cognito_user_pool_client.web_client[project_key].id,
          }
        },
        "content"     = {
          "appName"     = project_key,
          "clientId"    = "${project_key}:default",
          "clientSecret" = "krjqjgzs66fqyxzlck06nxgxtafvd0o2io5pneyhjpqx",
        },
        "analytics"   = {
          "apiKey" = "G-YMJ6PGPYQE",
        },
      }
    ])
  }
}  

resource "aws_ssm_parameter" "SiteConfig" {
  name      = "/${var.env}/config-service/config"
  type      = "SecureString"
  overwrite = true
  value     = data.template_file.site_parameter_value.rendered
  # lifecycle {
  #   ignore_changes = all
  # }
}

#resource "aws_s3_object" "site_config" {
#   bucket = var.config_bucket
#   key = "configurations/applicant-hub/config.json"
#   #acl    = "public-read"  # or can be "public-read"
#   content = templatefile(
#     "${path.module}/config.json.tftpl",
#     {
#       user_pool_id = var.cognito_pool_id
#       app_client_id = aws_cognito_user_pool_client.web_client.id
#       region = var.region
#       domain = var.domain
#       env = var.env
#       app_uri = var.squidex_uri
#       site_app_name = var.site_app_name
#       dns_name = var.dns_name
#     }
#   )
#   content_type = "application/json"
# }

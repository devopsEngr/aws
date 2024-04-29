# output "private_ip1_alb" {
#   value = data.aws_network_interface.alb-subnet1.private_ip
# }

# output "private_ip2_alb" {
#   value = data.aws_network_interface.alb-subnet2.private_ip
# }

# output "private_ip1_nlb" {
#   value = data.aws_network_interface.nlb-subnet1.private_ip
# }

# output "private_ip2_nlb" {
#   value = data.aws_network_interface.nlb-subnet2.private_ip
# }

resource "aws_lb" "apigateway_nlb" {
  name               = "${var.env}-apigateway-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]
  depends_on = [
    aws_acm_certificate_validation.example,
  ]
}

# resource "aws_alb_listener" "load_balancer_http_listener_nlb" {
#   load_balancer_arn = aws_lb.test.id
#   port              = 80
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.nlb_tg.arn
#   }
#     }

resource "aws_lb" "alb_external" {
  name               = "${var.env}-alb-external"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]

  tags = {
    Environment = var.env
    Type        = "Managed by Terraform"
  }
  depends_on = [
    aws_acm_certificate_validation.example,
  ]
}

resource "aws_lb" "alb_internal" {
  name               = "${var.env}-alb-internal"
  load_balancer_type = "application"
  internal           = true
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]

  tags = {
    Environment = var.env
    Type        = "Managed by Terraform"
  }
  depends_on = [
    aws_acm_certificate_validation.example,
  ]

}

resource "aws_lb_listener" "lb_apigateway" {
  load_balancer_arn = aws_lb.apigateway_nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
  depends_on = [
    aws_acm_certificate_validation.example,
  ]
}

resource "aws_lb_listener" "internal_https_listener" {
  load_balancer_arn = aws_lb.alb_internal.id
  port              = "443"
  protocol          = "HTTPS"
  #  ssl_policy        = "ELBSecurityPolicy-2016-08"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate_validation.example.certificate_arn

  lifecycle {
    create_before_destroy = true
  }

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "nothing"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener" "external_https_listener" {
  load_balancer_arn = aws_lb.alb_external.id
  port              = "443"
  protocol          = "HTTPS"
  #  ssl_policy        = "ELBSecurityPolicy-2016-08"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate_validation.example.certificate_arn

  lifecycle {
    create_before_destroy = true
  }

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "nothing"
      status_code  = "503"
    }
  }
}

resource "aws_lb_target_group" "alb-tg" {
  name        = "${var.env}-alb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  depends_on = [
    aws_acm_certificate_validation.example,
  ]

}

resource "aws_lb_target_group_attachment" "alb-tg" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_lb.alb_internal.arn
  depends_on = [
    aws_lb.alb_internal, aws_lb_target_group.alb-tg, aws_alb_listener.internal_http_listener
  ]
}

resource "aws_alb_listener" "internal_http_listener" {
  load_balancer_arn = aws_lb.alb_internal.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "nothing"
      status_code  = "503"
    }
  }
}

resource "aws_alb_listener" "external_http_listener" {
  load_balancer_arn = aws_lb.alb_external.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
#WAF2
resource "aws_wafv2_web_acl_association" "WafWebAcl" {
  resource_arn = aws_lb.alb_external.arn
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
}
#
# resource "aws_wafv2_web_acl_association" "WafWebAcl2" {
#   resource_arn = aws_lb.alb_internal.arn
#   web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
# }
#
resource "aws_wafv2_web_acl_association" "WafWebAcl3" {
  resource_arn = module.squidex-deploy.squidex_alb_arn
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl_Squidex.arn
}

resource "aws_wafv2_web_acl_association" "WafWebAcl4" {
  resource_arn = module.atribo-userapi.api_gateway_arn1[0]
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
}

resource "aws_wafv2_web_acl_association" "WafWebAcl5" {
  resource_arn = module.config-service.api_gateway_arn1[0]
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
}

resource "aws_wafv2_web_acl_association" "WafWebAcl6" {
  resource_arn = module.dms.api_gateway_arn1[0]
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
}

resource "aws_wafv2_web_acl_association" "WafWebAcl7" {
  resource_arn = module.sm-data-api.api_gateway_arn1[0]
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
}

resource "aws_wafv2_web_acl_association" "WafWebAcl8" {
  resource_arn = module.sm-portal-api.api_gateway_arn1[0]
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
}

resource "aws_wafv2_web_acl_association" "WafWebAcl9" {
  for_each = module.api
  resource_arn = each.value.cognito_arn
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
}

resource "aws_wafv2_web_acl_association" "WafWebAcl10" {
  for_each = module.api
  resource_arn = each.value.api_gw_arn_site
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
}


# Global Accelerator
resource "aws_globalaccelerator_accelerator" "aws-ga-internal" {
  name            = "reach-${var.env}-ga-internal"
  ip_address_type = "IPV4"
  enabled         = true
}
resource "aws_globalaccelerator_accelerator" "aws-ga-external" {
  name            = "reach-${var.env}-ga-external"
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "aws-ga-listener-internal" {
  accelerator_arn = aws_globalaccelerator_accelerator.aws-ga-internal.id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }
  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_listener" "aws-ga-listener-external" {
  accelerator_arn = aws_globalaccelerator_accelerator.aws-ga-external.id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"
  port_range {
    from_port = 80
    to_port   = 80
  }
  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "aws-ga-eg-internal" {
  listener_arn          = aws_globalaccelerator_listener.aws-ga-listener-internal.id
  endpoint_group_region = var.region
  health_check_port     = 443
  health_check_protocol = "HTTPS"

  endpoint_configuration {
    endpoint_id                    = aws_lb.alb_internal.arn
    client_ip_preservation_enabled = true
  }
}

resource "aws_globalaccelerator_endpoint_group" "aws-ga-eg-external" {
  listener_arn          = aws_globalaccelerator_listener.aws-ga-listener-external.id
  endpoint_group_region = var.region
  health_check_port     = 443
  health_check_protocol = "HTTPS"

  endpoint_configuration {
    endpoint_id                    = aws_lb.alb_external.arn
    client_ip_preservation_enabled = true
  }
}

data "aws_route53_zone" "public" {
  name = var.domain
}
locals {
  subdomainsList = {

    for pv in var.project_version : pv.project => {
      subdomain_name = "${pv.project}.${var.domain}"

    }
  }
}
module "acm_certificate_domain" {
  source   = "../../modules/acm_certificate"
  domain   = var.domain
  zoneid   = data.aws_route53_zone.public.id
  providers = {
    aws        = aws
    aws.global = aws.global
  }
}
module "acm_certificate_subdomain" {

  zoneid   = data.aws_route53_zone.public.id
  for_each = local.subdomainsList
  source   = "../../modules/acm_certificate"
  domain   = each.value.subdomain_name
  providers = {
    aws        = aws
    aws.global = aws.global
  }
  #depends_on = [module.acm_certificate_domain]
}

resource "aws_route53_record" "subdomains" {
  for_each = local.subdomainsList

  zone_id = data.aws_route53_zone.public.zone_id
  name    = "www.${each.value.subdomain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.engagement_hub_subdomains[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.engagement_hub_subdomains[each.key].hosted_zone_id
    evaluate_target_health = false
  }
    lifecycle {
    ignore_changes = all
  }

}
resource "aws_route53_record" "non-www_subdomains" {
  for_each = local.subdomainsList

  zone_id = data.aws_route53_zone.public.zone_id
  name    = each.value.subdomain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.engagement_hub_subdomains[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.engagement_hub_subdomains[each.key].hosted_zone_id
    evaluate_target_health = false
  }
    lifecycle {
    ignore_changes = all
  }
}

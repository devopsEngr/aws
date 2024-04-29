
resource "aws_s3_bucket" "engagement_hub" {
  bucket = "${var.env}-reach-engagement-hub"
  force_destroy = true
  tags = {
    Name        = "engagement-hub site"
    Environment = var.env
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_engagement_hub_bucket" {
  bucket = aws_s3_bucket.engagement_hub.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket" "survey_creator" {
  bucket = "${var.env}-reach-survey-creator"
  force_destroy = true
  tags = {
    Name        = "survey creator"
    Environment = var.env
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_survey_creator_bucket" {
  bucket = aws_s3_bucket.survey_creator.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.engagement_hub.id
  policy = data.aws_iam_policy_document.eh.json
}

data "aws_iam_policy_document" "eh" {
	statement {
		actions = ["s3:GetObject"]

		resources = ["${aws_s3_bucket.engagement_hub.arn}/*"]

		principals {
			type        = "Service"
			identifiers = ["cloudfront.amazonaws.com"]
		}
		condition {
			test     = "StringEquals"
			variable = "AWS:SourceArn"
			values   = [for _, dist in aws_cloudfront_distribution.engagement_hub_subdomains : dist.arn] #add all CF distributions of multiprojects to the policy
		}
	}
	statement {
		actions   = ["s3:GetObject"]
		resources = ["${aws_s3_bucket.engagement_hub.arn}/*"]

		principals {
			type        = "AWS"
			identifiers = [aws_cloudfront_origin_access_identity.engagement_hub.iam_arn]
		}
	}
}


resource "aws_s3_bucket_public_access_block" "engagement_hub_bucket" {
  bucket = aws_s3_bucket.engagement_hub.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "survey_creator" {

  bucket = aws_s3_bucket.survey_creator.id
	policy = data.aws_iam_policy_document.sc.json
}

data "aws_iam_policy_document" "sc" {
	statement {
		actions = ["s3:GetObject"]

		resources = ["${aws_s3_bucket.survey_creator.arn}/*"]

		principals {
			type        = "Service"
			identifiers = ["cloudfront.amazonaws.com"]
		}
		condition {
			test     = "StringEquals"
			variable = "AWS:SourceArn"
			values   = [for _, dist in aws_cloudfront_distribution.engagement_hub_subdomains : dist.arn]
      
		}
	}
	statement {
		actions   = ["s3:GetObject"]
		resources = ["${aws_s3_bucket.survey_creator.arn}/*"]

		principals {
			type        = "AWS"
			identifiers = [aws_cloudfront_origin_access_identity.survey_creator.iam_arn]
		}
	}
}

resource "aws_s3_bucket_public_access_block" "survey_creator_bucket" {
  bucket = aws_s3_bucket.survey_creator.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# output "website" {
#     value = aws_s3_bucket.engagement_hub.website_endpoint
# }

resource "null_resource" "sync_sitebuilder_website" {
   triggers = {
    always_run = timestamp()
    }
  provisioner "local-exec" {
    command = <<-EOT
      ${length(var.project_version) > 0 ?
        join("\n", [
          for version in var.project_version :
            "aws s3 sync s3://reach-sitebuilder/website_${version["version"]} s3://${aws_s3_bucket.engagement_hub.id}/website_${version["version"]} --source-region ap-southeast-2 --region ${var.region} --quiet --debug"
        ])
      : ""}
    EOT
    when = create
  }
  depends_on = [aws_s3_bucket.engagement_hub]
}

resource "null_resource" "sync_sitebuilder_creator" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = <<-EOT
      ${length(var.project_version) > 0 ?
        join("\n", [
          for version in var.project_version :
        "aws s3 sync s3://reach-sitebuilder/creator_${version["version"]} s3://${aws_s3_bucket.survey_creator.id}/creator_${version["version"]} --source-region ap-southeast-2 --region ${var.region} --quiet --debug"
        ])
      : ""}
    EOT
    when = create
  }
  depends_on = [aws_s3_bucket.survey_creator, null_resource.sync_sitebuilder_website]
}


# # Upload static site
# resource "aws_s3_object" "object_html" {
#   for_each = fileset("${path.module}/site/", "**/*.html")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "text/html"
#   # source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# resource "aws_s3_object" "object_css" {
#   for_each = fileset("${path.module}/site/", "**/*.css")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "text/css"
#   # source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# resource "aws_s3_object" "object_js" {
#   for_each = fileset("${path.module}/site/", "**/*.js")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "text/javascript"
#   # source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# resource "aws_s3_object" "object_png" {
#   for_each = fileset("${path.module}/site/", "**/*.png")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "image/png"
#   # source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# resource "aws_s3_object" "object_gif" {
#   for_each = fileset("${path.module}/site/", "**/*.gif")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "image/gif"
#   # source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# resource "aws_s3_object" "object_jpg" {
#   for_each = fileset("${path.module}/site/", "**/*.jpg")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "image/jpeg"
#   # source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# resource "aws_s3_object" "object_svg" {
#   for_each = fileset("${path.module}/site/", "**/*.svg")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "image/svg+xml"
#   # source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# resource "aws_s3_object" "object_ico" {
#   for_each = fileset("${path.module}/site/", "**/*.ico")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "image/vnd.microsoft.icon"
#   # source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# resource "aws_s3_object" "object_json" {
#   for_each = fileset("${path.module}/site/", "**/*.json")
#   bucket = aws_s3_bucket.engagement_hub.id
#   key = each.key
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/site/${each.key}"
#   content_type = "application/json"
#   source_hash = filemd5("${path.module}/site/${each.key}")
# }
#
# # Upload survey creator
# resource "aws_s3_object" "survey_object_html" {
#   for_each = fileset("${path.module}/survey-creator/", "**/*.html")
#   bucket = aws_s3_bucket.survey_creator.id
#   key = "/creator/${each.key}"
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/survey-creator/${each.key}"
#   content_type = "text/html"
#   # source_hash = filemd5("${path.module}/survey-creator/${each.key}")
# }
# resource "aws_s3_object" "survey_object_css" {
#   for_each = fileset("${path.module}/survey-creator/", "**/*.css")
#   bucket = aws_s3_bucket.survey_creator.id
#   key = "/creator/${each.key}"
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/survey-creator/${each.key}"
#   content_type = "text/css"
#   # source_hash = filemd5("${path.module}/survey-creator/${each.key}")
# }
# resource "aws_s3_object" "survey_object_js" {
#   for_each = fileset("${path.module}/survey-creator/", "**/*.js")
#   bucket = aws_s3_bucket.survey_creator.id
#   key = "/creator/${each.key}"
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/survey-creator/${each.key}"
#   content_type = "text/javascript"
#   # source_hash = filemd5("${path.module}/survey-creator/${each.key}")
# }
# resource "aws_s3_object" "survey_object_ico" {
#   for_each = fileset("${path.module}/survey-creator/", "**/*.ico")
#   bucket = aws_s3_bucket.survey_creator.id
#   key = "/creator/${each.key}"
#   acl    = "public-read"  # or can be "public-read"
#   source = "${path.module}/survey-creator/${each.key}"
#   content_type = "image/vnd.microsoft.icon"
#   # source_hash = filemd5("${path.module}/survey-creator/${each.key}")
# }

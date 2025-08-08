###############################################################################
# Terraform とプロバイダー設定（Route53 専用スタック）
###############################################################################
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

###############################################################################
# 変数
###############################################################################
variable "enable_destroy_protection" {
  description = "リソースの destroy を保護するフラグ。通常は true。destroy 時にのみ false にする"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Route53 に委任する apex ドメイン名（例: example.com）"
  type        = string
}

variable "cf_subdomain" {
  description = "CloudFront/ACM に割り当てるサブドメイン（空なら apex 自体）"
  type        = string
  default     = ""
}

variable "cloudfront_domain_name" {
  description = "CloudFront のドメイン名（例: dxxxxxxxxxxx.cloudfront.net）"
  type        = string
  default     = ""
}

########################################
# Day9 ディレクトリへの依存をなくすための入力/検出
########################################
locals {
  cf_domain_name = var.cf_subdomain != "" ? "${var.cf_subdomain}.${var.domain_name}" : var.domain_name
}

########################################
# ACM (us-east-1) for CloudFront + DNS validation
########################################

# CloudFront 用 ACM はバージニア北部(us-east-1)で発行する必要がある
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ACM 証明書（DNS 検証）
resource "aws_acm_certificate" "cf" {
  provider          = aws.us_east_1
  domain_name       = local.cf_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS 検証レコード（Hosted Zone 内に自動作成）
resource "aws_route53_record" "cf_cert_validation" {
  for_each = { for dvo in aws_acm_certificate.cf.domain_validation_options : dvo.domain_name => dvo }

  zone_id = aws_route53_zone.primary.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  allow_overwrite = true
  ttl     = 60
  records = [each.value.resource_record_value]
}

# 証明書バリデーション
resource "aws_acm_certificate_validation" "cf" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cf.arn
  validation_record_fqdns = [for r in aws_route53_record.cf_cert_validation : r.fqdn]
}

#############################
# Route 53: Public Hosted Zone
#############################
resource "aws_route53_zone" "primary" {
  name    = var.domain_name
  comment = "Public hosted zone for ${var.domain_name}"

  # lifecycle {
  #   prevent_destroy = var.enable_destroy_protection
  # }
}

# 便利な出力（お名前.com に設定する NS）
output "route53_name_servers" {
  description = "Route53 の NS（お名前.com に設定）"
  value       = aws_route53_zone.primary.name_servers
}

#############################
# A (ALIAS) : apex を ALB に向ける
#############################
resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"
  allow_overwrite = true

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront 固定 Hosted Zone ID
    evaluate_target_health = true
  }

  lifecycle {
    # prevent_destroy = var.enable_destroy_protection
    precondition {
      condition     = var.cloudfront_domain_name != ""
      error_message = "CloudFront ドメイン名が未指定です。Day9 の出力（cloudfront_domain_name）を tfvars で指定してください。"
    }
  }
}

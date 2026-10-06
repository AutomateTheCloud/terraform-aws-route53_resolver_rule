# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Two rules in a Region other than the provider's, both associated with one VPC:
#
# - a FORWARD rule for corp.example.org to three DNS servers, one on a custom port and
#   one over DNS over HTTPS, shared with one organizational unit under a custom share
#   name;
# - a SYSTEM rule for aws.corp.example.org, so queries for that subdomain are answered
#   in AWS as usual instead of being forwarded.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "region" {
  description = "The Region to create the rules in, such as us-west-2. The endpoint and the VPC must be in it."
  type        = string
}

variable "resolver_endpoint_id" {
  description = "ID of an outbound Resolver endpoint in var.region that supports Do53 and DoH, such as rslvr-out-0123456789abcdef0"
  type        = string
}

variable "vpc_id" {
  description = "ID of a VPC in var.region to use the rules in, such as vpc-0123456789abcdef0"
  type        = string
}

variable "workloads_ou_arn" {
  description = "ARN of the organizational unit to share the forwarding rule with, such as arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111"
  type        = string
}

locals {
  details = {
    scope            = "Example"
    purpose          = "Complete"
    environment      = "Development"
    environment_abbr = "dev"
    additional_tags  = { CostCenter = "1234" }
  }
}

module "forward_corp" {
  source = "../../"

  region  = var.region
  details = local.details

  name                 = "Forward corp"
  domain_name          = "corp.example.org"
  rule_type            = "FORWARD"
  resolver_endpoint_id = var.resolver_endpoint_id
  target_ips = [
    { ip = "192.0.2.10" },
    { ip = "192.0.2.11", port = 5353 },
    { ip = "192.0.2.12", port = 443, protocol = "DoH" },
  ]

  ram_share = {
    name                      = "corp-dns-forwarding"
    allow_external_principals = false
    principals                = { workloads = var.workloads_ou_arn }
  }
}

module "system_aws_corp" {
  source = "../../"

  region  = var.region
  details = local.details

  name        = "Answer aws corp in AWS"
  domain_name = "aws.corp.example.org"
  rule_type   = "SYSTEM"
}

resource "aws_route53_resolver_rule_association" "forward_corp" {
  region           = var.region
  resolver_rule_id = module.forward_corp.metadata.route53_resolver_rule.id
  vpc_id           = var.vpc_id
}

resource "aws_route53_resolver_rule_association" "system_aws_corp" {
  region           = var.region
  resolver_rule_id = module.system_aws_corp.metadata.route53_resolver_rule.id
  vpc_id           = var.vpc_id
}

output "forward_rule_id" {
  description = "ID of the forwarding rule, for associating it with more VPCs"
  value       = module.forward_corp.metadata.route53_resolver_rule.id
}

output "system_rule_id" {
  description = "ID of the SYSTEM rule"
  value       = module.system_aws_corp.metadata.route53_resolver_rule.id
}

output "resource_share_arn" {
  description = "ARN of the Resource Access Manager share for the forwarding rule"
  value       = module.forward_corp.metadata.ram_resource_share.arn
}

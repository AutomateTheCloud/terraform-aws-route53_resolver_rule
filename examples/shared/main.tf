# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A forwarding rule shared through AWS Resource Access Manager with one other account in
# the same AWS organization. That account can then associate the rule with its own VPCs.

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

variable "resolver_endpoint_id" {
  description = "ID of an outbound Resolver endpoint in us-east-1, such as rslvr-out-0123456789abcdef0"
  type        = string
}

variable "dns_servers" {
  description = "IPv4 addresses of the DNS servers that answer for corp.example.org, such as [\"192.0.2.10\", \"192.0.2.11\"]"
  type        = list(string)
}

variable "workload_account_id" {
  description = "ID of the AWS account to share the rule with, in the same AWS organization, such as 111111111111"
  type        = string
}

module "route53_resolver_rule" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Shared Rule"
    environment = "Development"
  }

  name                 = "Forward corp"
  domain_name          = "corp.example.org"
  resolver_endpoint_id = var.resolver_endpoint_id
  target_ips           = [for ip in var.dns_servers : { ip = ip }]

  # One account, not the whole organization. allow_external_principals stays false, so
  # RAM refuses the share if the account is not in your organization.
  ram_share = {
    principals = { workload = var.workload_account_id }
  }
}

output "resolver_rule_id" {
  description = "ID of the rule, for the other account's aws_route53_resolver_rule_association"
  value       = module.route53_resolver_rule.metadata.route53_resolver_rule.id
}

output "resource_share_arn" {
  description = "ARN of the Resource Access Manager share"
  value       = module.route53_resolver_rule.metadata.ram_resource_share.arn
}

# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Forwards queries for one domain, such as corp.example.org, through an existing outbound
# Resolver endpoint to DNS servers in your network, and associates the rule with a VPC.

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

variable "domain_name" {
  description = "The domain name to forward, such as corp.example.org"
  type        = string
}

variable "resolver_endpoint_id" {
  description = "ID of an outbound Resolver endpoint in us-east-1, such as rslvr-out-0123456789abcdef0"
  type        = string
}

variable "dns_servers" {
  description = "IPv4 addresses of the DNS servers that answer for the domain, such as [\"192.0.2.10\", \"192.0.2.11\"]"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of a VPC in us-east-1 to use the rule in, such as vpc-0123456789abcdef0"
  type        = string
}

module "route53_resolver_rule" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic Rule"
    environment = "Development"
  }

  name                 = "Forward to on-premises DNS"
  domain_name          = var.domain_name
  resolver_endpoint_id = var.resolver_endpoint_id
  target_ips           = [for ip in var.dns_servers : { ip = ip }]
}

resource "aws_route53_resolver_rule_association" "this" {
  resolver_rule_id = module.route53_resolver_rule.metadata.route53_resolver_rule.id
  vpc_id           = var.vpc_id
}

output "resolver_rule_id" {
  description = "ID of the rule, for associating it with more VPCs"
  value       = module.route53_resolver_rule.metadata.route53_resolver_rule.id
}

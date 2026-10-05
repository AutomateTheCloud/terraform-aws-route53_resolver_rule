# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A rule whose outbound endpoint, target address and RAM principal are all created in
# the same run, so their values are unknown at plan time.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

resource "aws_route53_resolver_endpoint" "outbound" {
  direction          = "OUTBOUND"
  security_group_ids = ["sg-0123456789abcdef0"]

  ip_address {
    subnet_id = "subnet-0123456789abcdef0"
  }
  ip_address {
    subnet_id = "subnet-0fedcba9876543210"
  }
}

resource "aws_route53_resolver_endpoint" "inbound" {
  direction          = "INBOUND"
  security_group_ids = ["sg-0123456789abcdef0"]

  ip_address {
    subnet_id = "subnet-0123456789abcdef0"
  }
  ip_address {
    subnet_id = "subnet-0fedcba9876543210"
  }
}

resource "aws_organizations_organizational_unit" "this" {
  name      = "Workloads"
  parent_id = "r-abcd"
}

module "rule" {
  source = "../../.."

  details              = { scope = "Test", purpose = "Same Run", environment = "test" }
  name                 = "Forward corp"
  domain_name          = "corp.example.com"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id
  target_ips           = [for a in aws_route53_resolver_endpoint.inbound.ip_address : { ip = a.ip }]

  ram_share = {
    principals = { workloads = aws_organizations_organizational_unit.this.arn }
  }
}

# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_route53_resolver_rule" {
    defaults = {
      id           = "rslvr-rr-0123456789abcdef0"
      arn          = "arn:aws:route53resolver:us-east-1:111111111111:resolver-rule/rslvr-rr-0123456789abcdef0"
      owner_id     = "111111111111"
      share_status = "NOT_SHARED"
    }
  }
  mock_resource "aws_ram_resource_share" {
    defaults = {
      id  = "arn:aws:ram:us-east-1:111111111111:resource-share/a1b2c3d4-5678-90ab-cdef-example11111"
      arn = "arn:aws:ram:us-east-1:111111111111:resource-share/a1b2c3d4-5678-90ab-cdef-example11111"
    }
  }
}

variables {
  details              = { scope = "Test", purpose = "Region", environment = "test" }
  name                 = "Forward corp"
  domain_name          = "corp.example.com"
  resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
  target_ips           = [{ ip = "10.0.0.2" }]
}

# No providers block anywhere in this file: the module uses the default aws provider.
run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = plan
  variables {
    region    = "eu-west-1"
    ram_share = { principals = { network = "222222222222" } }
  }
  assert {
    condition = alltrue([
      data.aws_region.this.region == "eu-west-1",
      aws_route53_resolver_rule.this.region == "eu-west-1",
      aws_ram_resource_share.this[0].region == "eu-west-1",
      aws_ram_resource_association.this[0].region == "eu-west-1",
      aws_ram_principal_association.this["network"].region == "eu-west-1",
      output.metadata.aws.region.name == "eu-west-1",
      aws_ram_resource_share.this[0].name == "r53_resolver_rule-forward_corp-euw1",
    ])
    error_message = "region was not passed through to every resource."
  }
}

# Regression: Regions missing from the old hard-coded table failed to plan.
run "region_not_in_old_table" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command = plan
  variables { region = "us-gov-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}

# Copyright 2025 Automate the Cloud Inc.
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
  details              = { scope = "Test", purpose = "Sharing", environment = "test" }
  name                 = "Forward corp"
  domain_name          = "corp.example.com"
  resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
  target_ips           = [{ ip = "10.0.0.2" }]
}

run "share_with_an_account" {
  command = plan
  variables {
    ram_share = { principals = { network = "222222222222" } }
  }
  assert {
    condition     = aws_ram_resource_share.this[0].name == "r53_resolver_rule-forward_corp-use1"
    error_message = "Unexpected default share name: ${aws_ram_resource_share.this[0].name}"
  }
  # Regression: sharing with an account always allowed principals outside the organization.
  assert {
    condition     = aws_ram_resource_share.this[0].allow_external_principals == false
    error_message = "allow_external_principals must default to false."
  }
  assert {
    condition     = aws_ram_principal_association.this["network"].principal == "222222222222"
    error_message = "Unexpected principal."
  }
  assert {
    condition     = aws_ram_resource_share.this[0].tags == tomap({ Scope = "Test", Purpose = "Sharing", Environment = "test" })
    error_message = "The share must be tagged."
  }
}

run "share_options" {
  command = plan
  variables {
    ram_share = {
      name                      = "corp-dns"
      allow_external_principals = true
      principals = {
        partner   = "012345678901"
        workloads = "arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111"
        everyone  = "arn:aws:organizations::111111111111:organization/o-exampleorgid"
      }
    }
  }
  assert {
    condition     = aws_ram_resource_share.this[0].name == "corp-dns" && aws_ram_resource_share.this[0].allow_external_principals == true
    error_message = "ram_share options did not reach the share."
  }
  assert {
    condition     = length(aws_ram_principal_association.this) == 3 && aws_ram_principal_association.this["workloads"].principal == "arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111"
    error_message = "Unexpected principals."
  }
}

# Regression: the account associations were output wrapped in a list, and the resource
# association was missing from the output.
run "share_outputs" {
  command = apply
  variables {
    ram_share = { principals = { network = "222222222222", security = "987654321098" } }
  }
  assert {
    condition     = output.metadata.ram_principal_association["network"].principal == "222222222222" && length(output.metadata.ram_principal_association) == 2
    error_message = "metadata.ram_principal_association must be keyed like ram_share.principals."
  }
  assert {
    condition     = output.metadata.ram_resource_association.resource_arn == "arn:aws:route53resolver:us-east-1:111111111111:resolver-rule/rslvr-rr-0123456789abcdef0"
    error_message = "metadata.ram_resource_association is wrong."
  }
  assert {
    condition     = output.metadata.ram_resource_share.arn == "arn:aws:ram:us-east-1:111111111111:resource-share/a1b2c3d4-5678-90ab-cdef-example11111"
    error_message = "metadata.ram_resource_share is wrong."
  }
  assert {
    condition     = aws_ram_resource_association.this[0].resource_share_arn == aws_ram_resource_share.this[0].arn && aws_ram_principal_association.this["security"].resource_share_arn == aws_ram_resource_share.this[0].arn
    error_message = "The associations must use the share's ARN."
  }
}

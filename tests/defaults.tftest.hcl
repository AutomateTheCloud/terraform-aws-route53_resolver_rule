# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
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
  details              = { scope = "Test", purpose = "Defaults", environment = "test" }
  name                 = "Forward corp"
  domain_name          = "corp.example.com"
  resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
  target_ips           = [{ ip = "10.0.0.2" }]
}

# Only the required inputs: a FORWARD rule to one server on port 53 with plain DNS, not
# shared with anyone.
run "defaults" {
  command = plan

  assert {
    condition = alltrue([
      aws_route53_resolver_rule.this.name == "Forward corp",
      aws_route53_resolver_rule.this.domain_name == "corp.example.com",
      aws_route53_resolver_rule.this.rule_type == "FORWARD",
      aws_route53_resolver_rule.this.resolver_endpoint_id == "rslvr-out-0123456789abcdef0",
    ])
    error_message = "Unexpected rule arguments."
  }
  assert {
    condition = alltrue([
      one(aws_route53_resolver_rule.this.target_ip).ip == "10.0.0.2",
      one(aws_route53_resolver_rule.this.target_ip).ipv6 == null,
      one(aws_route53_resolver_rule.this.target_ip).port == 53,
      one(aws_route53_resolver_rule.this.target_ip).protocol == "Do53",
    ])
    error_message = "A target must default to port 53 and Do53."
  }
  assert {
    condition     = length(aws_ram_resource_share.this) == 0 && length(aws_ram_resource_association.this) == 0 && length(aws_ram_principal_association.this) == 0
    error_message = "The rule must not be shared by default."
  }
  assert {
    condition     = aws_route53_resolver_rule.this.tags == tomap({ Scope = "Test", Purpose = "Defaults", Environment = "test" })
    error_message = "Unexpected tags."
  }
}

run "defaults_apply" {
  command = apply

  assert {
    condition     = output.metadata.route53_resolver_rule.id == "rslvr-rr-0123456789abcdef0" && output.metadata.route53_resolver_rule.share_status == "NOT_SHARED"
    error_message = "metadata.route53_resolver_rule is wrong."
  }
  assert {
    condition = alltrue([
      output.metadata.ram_resource_share == null,
      output.metadata.ram_resource_association == null,
      output.metadata.ram_principal_association == null,
    ])
    error_message = "The RAM entries must be null without ram_share."
  }
  assert {
    condition     = output.metadata.aws.account.id == "111111111111" && output.metadata.aws.region.abbr == "use1"
    error_message = "metadata.aws is wrong."
  }
  assert {
    condition     = output.metadata.details.purpose.abbr == "defaults" && output.metadata.details.purpose.machine == "defaults"
    error_message = "metadata.details is wrong."
  }
}

run "system_rule" {
  command = plan
  variables {
    rule_type            = "SYSTEM"
    domain_name          = "aws.corp.example.com"
    resolver_endpoint_id = null
    target_ips           = []
  }
  assert {
    condition     = aws_route53_resolver_rule.this.rule_type == "SYSTEM" && aws_route53_resolver_rule.this.resolver_endpoint_id == null && length(aws_route53_resolver_rule.this.target_ip) == 0
    error_message = "Unexpected SYSTEM rule."
  }
}

run "every_domain" {
  command = plan
  variables { domain_name = "." }
  assert {
    condition     = aws_route53_resolver_rule.this.domain_name == "."
    error_message = "domain_name . must be accepted."
  }
}

run "targets" {
  command = plan
  variables {
    target_ips = [
      { ip = "10.0.0.2" },
      { ip = "10.0.1.2", port = 5353 },
      { ip = "10.0.2.2", port = 443, protocol = "DoH-FIPS" },
    ]
    details = {
      scope           = "Test"
      purpose         = "Targets"
      environment     = "test"
      additional_tags = { CostCenter = "1234" }
    }
  }
  assert {
    condition = toset([for t in aws_route53_resolver_rule.this.target_ip : "${t.ip}|${t.ipv6 == null}|${t.port}|${t.protocol}"]) == toset([
      "10.0.0.2|true|53|Do53",
      "10.0.1.2|true|5353|Do53",
      "10.0.2.2|true|443|DoH-FIPS",
    ])
    error_message = "Unexpected targets."
  }
  assert {
    condition     = aws_route53_resolver_rule.this.tags["CostCenter"] == "1234"
    error_message = "additional_tags must reach the rule."
  }
}

# Regression: the old "address:port" parsing split IPv6 addresses at the first colon.
# Documentation addresses: valid syntax for the module; AWS itself rejects them.
run "ipv6_targets" {
  command = plan
  variables {
    target_ips = [
      { ipv6 = "2001:db8::2" },
      { ipv6 = "2001:db8::3", port = 443, protocol = "DoH" },
    ]
  }
  assert {
    condition = toset([for t in aws_route53_resolver_rule.this.target_ip : "${t.ipv6}|${t.ip == null}|${t.port}|${t.protocol}"]) == toset([
      "2001:db8::2|true|53|Do53",
      "2001:db8::3|true|443|DoH",
    ])
    error_message = "Unexpected IPv6 targets."
  }
}

# Regression: an empty abbreviation override used to produce an empty abbreviation.
run "empty_abbr_override_is_ignored" {
  command = plan
  variables {
    details = { scope = "Test", scope_abbr = "", purpose = "Web Site", purpose_abbr = "web", environment = "test" }
  }
  assert {
    condition     = output.metadata.details.scope.abbr == "test" && output.metadata.details.purpose.abbr == "web"
    error_message = "An empty override must fall back to the generated abbreviation."
  }
}

# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
}

variables {
  details              = { scope = "Test", purpose = "Validation", environment = "test" }
  name                 = "Forward corp"
  domain_name          = "corp.example.com"
  resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
  target_ips           = [{ ip = "10.0.0.2" }]
}

run "scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

# Regression: name and domain_name defaulted to "" and failed only inside the provider.
run "name_empty" {
  command = plan
  variables { name = "" }
  expect_failures = [var.name]
}

run "name_too_long" {
  command = plan
  variables { name = "a234567890123456789012345678901234567890123456789012345678901234x" }
  expect_failures = [var.name]
}

run "name_bad_character" {
  command = plan
  variables { name = "corp.example.com" }
  expect_failures = [var.name]
}

run "name_only_digits" {
  command = plan
  variables { name = "12345" }
  expect_failures = [var.name]
}

run "domain_name_empty" {
  command = plan
  variables { domain_name = "" }
  expect_failures = [var.domain_name]
}

run "domain_name_bad" {
  command = plan
  variables { domain_name = "corp..example.com" }
  expect_failures = [var.domain_name]
}

# AWS accepts a wildcard first label, so the module does too.
run "domain_name_wildcard_allowed" {
  command = plan
  variables { domain_name = "*.corp.example.com" }
}

run "domain_name_wildcard_not_first" {
  command = plan
  variables { domain_name = "corp.*.example.com" }
  expect_failures = [var.domain_name]
}

run "domain_name_label_too_long" {
  command = plan
  variables { domain_name = "b234567890123456789012345678901234567890123456789012345678901234.example.com" }
  expect_failures = [var.domain_name]
}

run "domain_name_trailing_period_allowed" {
  command = plan
  variables { domain_name = "corp.example.com." }
}

# Regression: RECURSIVE was accepted, and AWS rejects it at apply.
run "rule_type_recursive" {
  command = plan
  variables {
    rule_type            = "RECURSIVE"
    resolver_endpoint_id = null
    target_ips           = []
  }
  expect_failures = [var.rule_type]
}

run "rule_type_lowercase" {
  command = plan
  variables { rule_type = "forward" }
  expect_failures = [var.rule_type]
}

# Regression: a FORWARD rule with no endpoint or no targets planned, and failed at apply.
run "forward_needs_endpoint" {
  command = plan
  variables { resolver_endpoint_id = null }
  expect_failures = [var.resolver_endpoint_id]
}

run "forward_needs_targets" {
  command = plan
  variables { target_ips = [] }
  expect_failures = [var.target_ips]
}

run "system_rejects_endpoint" {
  command = plan
  variables {
    rule_type  = "SYSTEM"
    target_ips = []
  }
  expect_failures = [var.resolver_endpoint_id]
}

run "system_rejects_targets" {
  command = plan
  variables {
    rule_type            = "SYSTEM"
    resolver_endpoint_id = null
  }
  expect_failures = [var.target_ips]
}

run "endpoint_inbound" {
  command = plan
  variables { resolver_endpoint_id = "rslvr-in-0123456789abcdef0" }
  expect_failures = [var.resolver_endpoint_id]
}

run "target_neither_address" {
  command = plan
  variables { target_ips = [{ port = 53 }] }
  expect_failures = [var.target_ips]
}

run "target_both_addresses" {
  command = plan
  variables { target_ips = [{ ip = "10.0.0.2", ipv6 = "2001:db8::2" }] }
  expect_failures = [var.target_ips]
}

# Regression: the old input took "address:port" strings.
run "target_ip_with_port" {
  command = plan
  variables { target_ips = [{ ip = "10.0.0.2:53" }] }
  expect_failures = [var.target_ips]
}

# Found in AWS: "Resolver rule target IP addresses can only have one type of Ip Address".
run "target_mixed_address_types" {
  command = plan
  variables { target_ips = [{ ip = "10.0.0.2" }, { ipv6 = "2001:db8::2" }] }
  expect_failures = [var.target_ips]
}

run "target_ip_bad" {
  command = plan
  variables { target_ips = [{ ip = "10.0.0.256" }] }
  expect_failures = [var.target_ips]
}

run "target_ipv6_given_as_ip" {
  command = plan
  variables { target_ips = [{ ip = "2001:db8::2" }] }
  expect_failures = [var.target_ips]
}

run "target_ipv4_given_as_ipv6" {
  command = plan
  variables { target_ips = [{ ipv6 = "10.0.0.2" }] }
  expect_failures = [var.target_ips]
}

run "target_port_zero" {
  command = plan
  variables { target_ips = [{ ip = "10.0.0.2", port = 0 }] }
  expect_failures = [var.target_ips]
}

run "target_port_too_high" {
  command = plan
  variables { target_ips = [{ ip = "10.0.0.2", port = 65536 }] }
  expect_failures = [var.target_ips]
}

run "target_port_fraction" {
  command = plan
  variables { target_ips = [{ ip = "10.0.0.2", port = 53.5 }] }
  expect_failures = [var.target_ips]
}

run "target_protocol" {
  command = plan
  variables { target_ips = [{ ip = "10.0.0.2", protocol = "DoT" }] }
  expect_failures = [var.target_ips]
}

run "ram_share_no_principals" {
  command = plan
  variables { ram_share = { principals = {} } }
  expect_failures = [var.ram_share]
}

# Regression: account IDs given as numbers lost leading zeros, or failed for_each.
run "ram_share_account_lost_leading_zero" {
  command = plan
  variables { ram_share = { principals = { network = 012345678901 } } }
  expect_failures = [var.ram_share]
}

run "ram_share_bad_principal" {
  command = plan
  variables { ram_share = { principals = { role = "arn:aws:iam::222222222222:role/dns" } } }
  expect_failures = [var.ram_share]
}

run "ram_share_empty_name" {
  command = plan
  variables {
    ram_share = { name = " ", principals = { network = "222222222222" } }
  }
  expect_failures = [var.ram_share]
}

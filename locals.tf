# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # Whether ram_share is null is known at plan time even when its principals come from
  # resources created in the same run, so it can decide count and for_each.
  ram_share_enabled = var.ram_share != null
  ram_principals    = local.ram_share_enabled ? var.ram_share.principals : {}
  ram_share_name    = local.ram_share_enabled ? coalesce(var.ram_share.name, "r53_resolver_rule-${lower(replace(replace(var.name, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_"))}-${local.aws.region.abbr}") : null
}

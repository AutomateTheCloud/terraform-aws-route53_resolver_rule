# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_ram_resource_share" "this" {
  count = local.ram_share_enabled ? 1 : 0

  region                    = var.region
  name                      = local.ram_share_name
  allow_external_principals = var.ram_share.allow_external_principals
  tags                      = local.tags
}

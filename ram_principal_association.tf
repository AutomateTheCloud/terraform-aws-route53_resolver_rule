# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Keyed by the names in ram_share.principals, which are known at plan time even when
# the account IDs or ARNs are not.
resource "aws_ram_principal_association" "this" {
  for_each = local.ram_principals

  region             = var.region
  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

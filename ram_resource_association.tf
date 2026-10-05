# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_ram_resource_association" "this" {
  count = local.ram_share_enabled ? 1 : 0

  region             = var.region
  resource_arn       = aws_route53_resolver_rule.this.arn
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

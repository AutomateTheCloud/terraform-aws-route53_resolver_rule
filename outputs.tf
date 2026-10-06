# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the Region the rule is in.
    - `route53_resolver_rule` - The rule: its `id` (use this to associate the rule with a VPC), `arn`, `name`, `domain_name`, `rule_type`, `resolver_endpoint_id`, `target_ip` (each with its `ip`, `ipv6`, `port` and `protocol`), `owner_id`, `share_status` (`NOT_SHARED`, `SHARED_BY_ME` or `SHARED_WITH_ME`), `region`, `tags` and `tags_all`.
    - `ram_resource_share` - The Resource Access Manager (RAM) resource share: its `arn`, `id`, `name`, `allow_external_principals`, `region`, `tags` and `tags_all`. `null` without `ram_share`.
    - `ram_resource_association` - The association of the rule with the resource share: its `id`, `resource_arn`, `resource_share_arn` and `region`. `null` without `ram_share`.
    - `ram_principal_association` - The principals the rule is shared with, keyed like `ram_share.principals`, each with its `id`, `principal`, `resource_share_arn` and `region`. `null` without `ram_share`.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    route53_resolver_rule     = local.output_resources.route53_resolver_rule
    ram_resource_share        = local.output_resources.ram_resource_share
    ram_resource_association  = local.output_resources.ram_resource_association
    ram_principal_association = local.output_resources.ram_principal_association
  }
}

# Each resource's attributes, listed one by one: referencing a whole resource would
# also reference its deprecated and sensitive attributes, and every caller's plan
# would then print warnings or the output would become sensitive.
locals {
  output_resources = {
    route53_resolver_rule = {
      arn                  = aws_route53_resolver_rule.this.arn
      domain_name          = aws_route53_resolver_rule.this.domain_name
      id                   = aws_route53_resolver_rule.this.id
      name                 = aws_route53_resolver_rule.this.name
      owner_id             = aws_route53_resolver_rule.this.owner_id
      region               = aws_route53_resolver_rule.this.region
      resolver_endpoint_id = aws_route53_resolver_rule.this.resolver_endpoint_id
      rule_type            = aws_route53_resolver_rule.this.rule_type
      share_status         = aws_route53_resolver_rule.this.share_status
      tags                 = aws_route53_resolver_rule.this.tags
      tags_all             = aws_route53_resolver_rule.this.tags_all
      target_ip            = aws_route53_resolver_rule.this.target_ip
    }

    # Left out: resource_share_configuration, which is newer than the provider floor, and
    # permission_arns, which AWS fills in when the rule is added to the share, after the
    # share is saved, so the next plan would show the output changing (seen in AWS for
    # terraform-aws-transit_gateway on provider 6.67.0).
    ram_resource_share = length(aws_ram_resource_share.this) == 0 ? null : {
      allow_external_principals = aws_ram_resource_share.this[0].allow_external_principals
      arn                       = aws_ram_resource_share.this[0].arn
      id                        = aws_ram_resource_share.this[0].id
      name                      = aws_ram_resource_share.this[0].name
      region                    = aws_ram_resource_share.this[0].region
      tags                      = aws_ram_resource_share.this[0].tags
      tags_all                  = aws_ram_resource_share.this[0].tags_all
    }

    ram_resource_association = length(aws_ram_resource_association.this) == 0 ? null : {
      id                 = aws_ram_resource_association.this[0].id
      region             = aws_ram_resource_association.this[0].region
      resource_arn       = aws_ram_resource_association.this[0].resource_arn
      resource_share_arn = aws_ram_resource_association.this[0].resource_share_arn
    }

    # Keyed like var.ram_share.principals.
    ram_principal_association = local.ram_share_enabled ? {
      for k in keys(local.ram_principals) : k => {
        id                 = aws_ram_principal_association.this[k].id
        principal          = aws_ram_principal_association.this[k].principal
        region             = aws_ram_principal_association.this[k].region
        resource_share_arn = aws_ram_principal_association.this[k].resource_share_arn
      }
    } : null
  }
}

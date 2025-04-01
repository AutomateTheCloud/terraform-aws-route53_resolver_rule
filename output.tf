output "metadata" {
  description = "Metadata"
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

    route53_resolver_rule = try(aws_route53_resolver_rule.this, null)
    ram_resource_share    = try(aws_ram_resource_share.this[0], null)
    ram_principal_association = {
      account      = try(aws_ram_principal_association.account[*], null)
      organization = try(aws_ram_principal_association.organization, null)
    }
  }
}

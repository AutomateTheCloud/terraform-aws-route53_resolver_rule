resource "aws_ram_resource_share" "this" {
  count                     = (var.enable_share_with_organization || local.enable_share_with_accounts ? 1 : 0)
  name                      = "r53_resolver_rule-${lower(replace(replace(var.name, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_"))}-${local.aws.region.abbr}"
  allow_external_principals = (local.enable_share_with_accounts ? true : false)
  tags                      = local.tags
  provider                  = aws.this
}

resource "aws_ram_resource_association" "this" {
  count              = (var.enable_share_with_organization || local.enable_share_with_accounts ? 1 : 0)
  resource_arn       = aws_route53_resolver_rule.this.arn
  resource_share_arn = try(aws_ram_resource_share.this[0].id, "")
  provider           = aws.this
}

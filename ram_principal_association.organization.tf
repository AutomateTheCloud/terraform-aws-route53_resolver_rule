data "aws_organizations_organization" "this" {
  count    = (var.enable_share_with_organization ? 1 : 0)
  provider = aws.this
}

resource "aws_ram_principal_association" "organization" {
  count              = (var.enable_share_with_organization ? 1 : 0)
  principal          = try(data.aws_organizations_organization.this[0].arn, "")
  resource_share_arn = try(aws_ram_resource_share.this[0].id, "")
  provider           = aws.this
}

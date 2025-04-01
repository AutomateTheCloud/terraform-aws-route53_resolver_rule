locals {
  enable_share_with_accounts = length(var.account_share) > 0 ? true : false
}

resource "aws_ram_principal_association" "account" {
  for_each           = try(toset(var.account_share), [])
  principal          = each.key
  resource_share_arn = try(aws_ram_resource_share.this[0].id, "")
  provider           = aws.this
}

resource "aws_route53_resolver_rule" "this" {
  name                 = var.name
  domain_name          = var.domain_name
  rule_type            = var.rule_type
  resolver_endpoint_id = var.resolver_endpoint_id

  dynamic "target_ip" {
    for_each = var.target_ip
    content {
      ip   = split(":", target_ip.value)[0]
      port = length(split(":", target_ip.value)) == 1 ? 53 : split(":", target_ip.value)[1]
    }
  }

  tags     = local.tags
  provider = aws.this
}

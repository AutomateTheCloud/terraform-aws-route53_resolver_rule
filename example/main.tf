terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: Route53 Resolver Rule
module "route53_resolver_rule" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope        = "Demo"
    purpose      = "Route53 Resolver Rule"
    purpose_abbr = "route53_resolver_rule"
    environment  = "prd"
    additional_tags = {
      "Project"   = "Project Name"
      "ProjectID" = "123456789"
      "Contact"   = "David Singer - david.singer@example.com"
    }
  }

  name                 = "test_rule"
  domain_name          = "."
  resolver_endpoint_id = "rslvr-out-606d924413b5433ba"
  rule_type            = "FORWARD"
  target_ip = [
    "8.8.8.8",
    "8.8.4.4",
  ]


  enable_share_with_organization         = true
  # account_share = [
    # "123456789012",
  # ]
}

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value       = module.route53_resolver_rule.metadata
}

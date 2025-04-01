# AWS - Route53 - Resolver Rule - Terraform Module
Terraform module to create Route53 Resolver Rules (AutomateTheCloud model)

***

## Usage
```hcl
module "route53_resolver_rule" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope        = "Infrastructure"
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
  resolver_endpoint_id = "rslvr-out-c3c9a8fadfb14f8ab"
  rule_type            = "FORWARD"
  target_ip = [
    "8.8.8.8",
    "8.8.4.4",
  ]


  # enable_share_with_organization         = true
  account_share = [
    "123456789012",
  ]
}
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `account_share` | Account Share | `list` | `[]` |
| `domain_name` | Domain Name | `string` | |
| `enable_share_with_organization` | Share the Transit Gateway with the AWS Organization | `bool` | `false` |
| `name` | Name | `string` | |
| `resolver_endpoint_id` | Resolver Endpoint ID | `string` | |
| `rule_type` | Rule Type (FORWARD|SYSTEM|RECURSIVE) | `string` | `FORWARD` |
| `target_ip` | Target IP (ex: 127.0.0.1:53) | `list` | `[]` |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object server? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `aws.account.id` | AWS Account ID |
| `aws.region.name` | AWS Region name, example: `us-east-1` |
| `aws.region.abbr` | AWS Region four letter abbreviation, example: `use1` |
| `aws.region.description` | AWS Region description, example: `US East (N. Virginia)` |
| `route53_resolver_rule` | Route53 Resolver Rule |
| `ram_resource_share` | RAM Resource Share Details |
| `ram_principal_association.account` | RAM Principal Association - Account |
| `ram_principal_association.organization` | RAM Principal Association - Organization |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |

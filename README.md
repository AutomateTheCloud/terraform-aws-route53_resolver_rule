# Terraform module for Amazon Route 53 Resolver rules

Creates a Route 53 Resolver rule, which tells the DNS resolver in your VPCs how to answer queries for a domain: forward them to DNS servers you choose, such as the servers in your data center, or answer them as usual. It can also share the rule with other AWS accounts through AWS Resource Access Manager (RAM), so their VPCs can use it too.

A rule created with only the required inputs forwards queries for one domain through an outbound Resolver endpoint to plain DNS servers on port 53, and is not shared with anyone. Sharing is an explicit opt-in, limited to the accounts, organizational units or organization you list, and to your own AWS organization unless you allow more.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Domain name the rule applies to | Required | `domain_name` |
| Rule name | Required | `name` |
| What the rule does | Forward to DNS servers | `rule_type` (`FORWARD` or `SYSTEM`) |
| Outbound endpoint | Required for `FORWARD` | `resolver_endpoint_id` |
| DNS servers | Required for `FORWARD`; port 53, plain DNS (`Do53`) | `target_ips` |
| Shared with other accounts | Not shared | `ram_share` |
| Sharing outside your AWS organization | Not allowed | `ram_share.allow_external_principals` |
| Region | The provider's | `region` |

## Usage

```hcl
module "route53_resolver_rule" {
  source  = "AutomateTheCloud/route53_resolver_rule/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Hybrid DNS"
    environment = "Production"
  }

  name                 = "Forward corp"
  domain_name          = "corp.example.org"
  resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
  target_ips = [
    { ip = "192.0.2.10" },
    { ip = "192.0.2.11" },
  ]
}

# The rule applies to a VPC only once it is associated with it.
resource "aws_route53_resolver_rule_association" "corp" {
  resolver_rule_id = module.route53_resolver_rule.metadata.route53_resolver_rule.id
  vpc_id           = "vpc-0123456789abcdef0"
}
```

`details`, `name` and `domain_name` are always required; a `FORWARD` rule, the default, also needs `resolver_endpoint_id` and `target_ips`. `details` sets the `Scope`, `Purpose` and `Environment` tags on every resource. Queries from the associated VPC for `corp.example.org`, and for every name under it, now go through the outbound endpoint to `192.0.2.10` or `192.0.2.11`.

The rule is created in the provider's Region unless you set `region`. The outbound endpoint and the VPCs must be in the same Region as the rule:

```hcl
module "route53_resolver_rule_west" {
  source  = "AutomateTheCloud/route53_resolver_rule/aws"
  version = "~> 1.0"

  region               = "us-west-2"
  details              = { scope = "Automate the Cloud", purpose = "Hybrid DNS", environment = "Production" }
  name                 = "Forward corp"
  domain_name          = "corp.example.org"
  resolver_endpoint_id = "rslvr-out-0fedcba9876543210" # in us-west-2
  target_ips           = [{ ip = "192.0.2.10" }]
}
```

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the resolver rule belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Hybrid DNS"         # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a resolver rule in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the resolver rule, its outbound endpoint, the VPCs that use it and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Hybrid DNS"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "corp_dns_rule" {
  source  = "AutomateTheCloud/route53_resolver_rule/aws"
  version = "~> 1.0"

  details              = local.details
  name                 = "Forward corp"
  domain_name          = "corp.example.org"
  resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
  target_ips           = [{ ip = "192.0.2.10" }]
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Hybrid DNS` becomes `hybrid_dns`), and `machine`, lowercase letters and numbers only (`hybriddns`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.corp_dns_rule.metadata.route53_resolver_rule.id` for the rule's ID, or `module.corp_dns_rule.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`. Each needs an outbound Resolver endpoint that already exists; an endpoint is billed for every hour it exists, for each of its IP addresses.

- [Basic rule](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/tree/main/examples/basic): forwards queries for one domain to DNS servers in your network, and associates the rule with a VPC.
- [Shared rule](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/tree/main/examples/shared): a rule shared with one other account in your AWS organization, which can then use it in its own VPCs.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/tree/main/examples/complete): a forwarding rule with servers on a custom port and over DNS over HTTPS, a `SYSTEM` rule that makes an exception for one subdomain, a shared rule with a custom share name, and a Region other than the provider's.

## Things to know

### A rule applies only to the VPCs it is associated with

Creating a rule changes nothing until it is associated with a VPC. The module does not create associations, because a rule is usually associated with VPCs that other configurations own, often in other accounts. Associate it with an `aws_route53_resolver_rule_association` resource, using the `metadata` output's `route53_resolver_rule.id`, as in [Usage](#usage). A VPC can have only one rule for a given domain name.

### Which rule answers

When several rules match a query, the Resolver uses the rule with the most specific domain name: a rule for `aws.corp.example.org` wins over one for `corp.example.org`, which wins over one for `.` (every domain name). Queries that no rule matches are answered as usual: from private hosted zones associated with the VPC, VPC names, then the internet. A `SYSTEM` rule restores that usual behavior for a subdomain of a `FORWARD` rule, which the [complete example](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/tree/main/examples/complete) shows.

### Forwarding needs a working path

A `FORWARD` rule sends queries out through the outbound endpoint in `resolver_endpoint_id`, from the endpoint's IP addresses in its subnets. Its security group must allow outbound traffic to each server in `target_ips` on the server's port, over UDP and TCP for `Do53` or TCP for `DoH`. The servers must be reachable from the endpoint's subnets, for example over AWS Direct Connect, a VPN or a transit gateway, and their firewalls must accept queries from those addresses. If any of this is missing, the rule is created without error, but queries for its domain fail. AWS does reject the rule, when it is created or changed, if a server's protocol is not enabled on the endpoint, or if a server is on IPv6 and the endpoint has only IPv4 addresses.

### Sharing the rule with other accounts

With `ram_share`, the module creates a Resource Access Manager (RAM) resource share, adds the rule to it, and shares it with each principal in `ram_share.principals`: an account, an organizational unit or a whole organization. The accounts that receive the rule can associate it with their own VPCs, which then use your outbound endpoint and your DNS servers. They cannot change or delete it. Share with the narrowest group that needs the rule.

By default the share accepts only principals in your own AWS organization. Sharing within an organization needs sharing with AWS Organizations turned on once, in the organization's management account (`aws ram enable-sharing-with-aws-organization`). The accounts then receive the rule without an invitation. To share with an account outside your organization, set `ram_share.allow_external_principals = true`; that account then gets an invitation, which it must accept, for example with an `aws_ram_resource_share_accepter` resource.

Removing a principal from `ram_share.principals` stops sharing with it, and removing `ram_share` deletes the share. The rule itself is not changed.

### Destroying a rule

Route 53 Resolver will not delete a rule while it is associated with any VPC, including VPCs in the accounts it is shared with. Remove the associations first.

### Changing the domain name or the rule type

Changing `domain_name` or `rule_type` replaces the rule. The new rule has a new ID, so every association in the same configuration that refers to the old ID is replaced too: Terraform removes the association, deletes the old rule, creates the new one and associates it again, and the VPC does not use the rule in between, a few minutes in testing. An association made anywhere else, such as in another configuration or in an account the rule is shared with, blocks the replacement: the delete fails and the old rule stays. Remove such associations first, and recreate them for the new rule. Changes to `name`, `resolver_endpoint_id`, `target_ips` and `ram_share` are applied in place.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against a mocked AWS provider, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_domain_name"></a> [domain_name](#input_domain_name)

Description: The domain name the rule applies to, such as `example.com`: the rule matches queries for this name and every name under it, unless a rule for a longer name also matches. `.` matches every domain name, so a `FORWARD` rule for `.` sends all queries that no other rule matches to `target_ips`. AWS also accepts a wildcard first label, such as `*.example.com`. 1 to 256 characters; a trailing period is ignored. Changing it replaces the rule, and its Resource Access Manager (RAM) share association with it.

Type: `string`

#### <a name="input_name"></a> [name](#input_name)

Description: A name for the rule, shown in the Route 53 Resolver console, such as `Forward corp`. Up to 64 letters, digits, spaces, hyphens and underscores, and not only digits. It can be changed without replacing the rule.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_ram_share"></a> [ram_share](#input_ram_share)

Description: Shares the rule with other AWS accounts through AWS Resource Access Manager (RAM), so that they can associate it with their own VPCs. Defaults to `null`: the rule is not shared. The accounts that receive the rule can use it, but cannot change or delete it.

- `principals` - (Required) Who to share the rule with, as a map from a name you choose to an AWS account ID (`111111111111`), an organizational unit ARN (`arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111`) or an organization ARN (`arn:aws:organizations::111111111111:organization/o-exampleorgid`). At least one. The names are only keys for Terraform, so a principal can be added or removed without affecting the others. Share with the narrowest group that needs the rule: an organization ARN shares it with every account in the organization.
- `allow_external_principals` - (Optional) Allow sharing with accounts outside your AWS organization. Defaults to `false`: RAM then accepts only principals in your organization, which must have sharing with AWS Organizations turned on. With `true`, each account outside the organization gets an invitation that it must accept.
- `name` - (Optional) The name of the resource share. Defaults to `r53_resolver_rule-<name>-<Region abbreviation>`, from the rule's `name` in lowercase with words joined by underscores, such as `r53_resolver_rule-forward_corp-use1` for the name `Forward corp` in us-east-1.

Type:

```hcl
object({
    principals                = map(string)
    allow_external_principals = optional(bool, false)
    name                      = optional(string)
  })
```

Default: `null`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the rule and its resource share in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The outbound endpoint in `resolver_endpoint_id`, and the VPCs that use the rule, must be in the same Region.

Type: `string`

Default: `null`

#### <a name="input_resolver_endpoint_id"></a> [resolver_endpoint_id](#input_resolver_endpoint_id)

Description: The ID of the outbound Resolver endpoint that forwards the queries, such as `rslvr-out-0123456789abcdef0`. Required for a `FORWARD` rule, and must be left `null` for a `SYSTEM` rule. Defaults to `null`. It can be changed without replacing the rule. The endpoint must support each protocol used in `target_ips`, or AWS rejects the rule.

Type: `string`

Default: `null`

#### <a name="input_rule_type"></a> [rule_type](#input_rule_type)

Description: What the rule does with matching queries:

- `FORWARD` - (Default) Forward them through the outbound endpoint in `resolver_endpoint_id` to the DNS servers in `target_ips`, such as servers in your data center.
- `SYSTEM` - Have the Route 53 Resolver answer them itself. Use it to make an exception to a `FORWARD` rule for a parent domain: a `SYSTEM` rule for `aws.example.com` keeps those queries in AWS while a `FORWARD` rule sends the rest of `example.com` elsewhere.

Changing it replaces the rule.

Type: `string`

Default: `"FORWARD"`

#### <a name="input_target_ips"></a> [target_ips](#input_target_ips)

Description: The DNS servers a `FORWARD` rule sends queries to. Required, at least one, for a `FORWARD` rule; must be empty for a `SYSTEM` rule. Defaults to `[]`. The list can be changed without replacing the rule. Each server is an object:

- `ip` - (Optional) An IPv4 address, such as `10.0.0.2`. Set exactly one of `ip` and `ipv6`, and use the same one in every entry: AWS rejects a rule with both IPv4 and IPv6 servers.
- `ipv6` - (Optional) An IPv6 address. The outbound endpoint must be of type `IPV6` or `DUALSTACK`, or AWS rejects the rule.
- `port` - (Optional) The port, 1 to 65535. Defaults to `53`.
- `protocol` - (Optional) `Do53` (plain DNS), `DoH` (DNS over HTTPS) or `DoH-FIPS` (DNS over HTTPS with FIPS-validated encryption). Defaults to `Do53`. The outbound endpoint must support it, or AWS rejects the rule; DoH servers usually listen on port 443.

AWS also rejects addresses it treats as reserved. In testing these included link-local IPv4 addresses such as `169.254.169.253`, IPv6 unique local addresses (`fd00::/8`) and the IPv6 documentation range (`2001:db8::/32`).

Type:

```hcl
list(object({
    ip       = optional(string)
    ipv6     = optional(string)
    port     = optional(number, 53)
    protocol = optional(string, "Do53")
  }))
```

Default: `[]`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the Region the rule is in.
- `route53_resolver_rule` - The rule: its `id` (use this to associate the rule with a VPC), `arn`, `name`, `domain_name`, `rule_type`, `resolver_endpoint_id`, `target_ip` (each with its `ip`, `ipv6`, `port` and `protocol`), `owner_id`, `share_status` (`NOT_SHARED`, `SHARED_BY_ME` or `SHARED_WITH_ME`), `region`, `tags` and `tags_all`.
- `ram_resource_share` - The Resource Access Manager (RAM) resource share: its `arn`, `id`, `name`, `allow_external_principals`, `region`, `tags` and `tags_all`. `null` without `ram_share`.
- `ram_resource_association` - The association of the rule with the resource share: its `id`, `resource_arn`, `resource_share_arn` and `region`. `null` without `ram_share`.
- `ram_principal_association` - The principals the rule is shared with, keyed like `ram_share.principals`, each with its `id`, `principal`, `resource_share_arn` and `region`. `null` without `ram_share`.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.

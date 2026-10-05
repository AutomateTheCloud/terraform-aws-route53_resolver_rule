# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "domain_name" {
  description = <<-EOT
    The domain name the rule applies to, such as `example.com`: the rule matches queries for this name and every name under it, unless a rule for a longer name also matches. `.` matches every domain name, so a `FORWARD` rule for `.` sends all queries that no other rule matches to `target_ips`. AWS also accepts a wildcard first label, such as `*.example.com`. 1 to 256 characters; a trailing period is ignored. Changing it replaces the rule, and its Resource Access Manager (RAM) share association with it.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = var.domain_name == "." || (length(var.domain_name) <= 256 && can(regex("^(\\*\\.)?([A-Za-z0-9_]([A-Za-z0-9_-]{0,61}[A-Za-z0-9_])?\\.)*[A-Za-z0-9_]([A-Za-z0-9_-]{0,61}[A-Za-z0-9_])?\\.?$", var.domain_name)))
    error_message = "domain_name must be a domain name, such as example.com, or \".\" for every domain name."
  }
}

variable "name" {
  description = <<-EOT
    A name for the rule, shown in the Route 53 Resolver console, such as `Forward corp`. Up to 64 letters, digits, spaces, hyphens and underscores, and not only digits. It can be changed without replacing the rule.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64 && can(regex("^[0-9A-Za-z _-]+$", var.name)) && !can(regex("^[0-9]+$", var.name))
    error_message = "name must be 1 to 64 letters, digits, spaces, hyphens and underscores, and not only digits."
  }
}

variable "ram_share" {
  description = <<-EOT
    Shares the rule with other AWS accounts through AWS Resource Access Manager (RAM), so that they can associate it with their own VPCs. Defaults to `null`: the rule is not shared. The accounts that receive the rule can use it, but cannot change or delete it.

    - `principals` - (Required) Who to share the rule with, as a map from a name you choose to an AWS account ID (`111111111111`), an organizational unit ARN (`arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111`) or an organization ARN (`arn:aws:organizations::111111111111:organization/o-exampleorgid`). At least one. The names are only keys for Terraform, so a principal can be added or removed without affecting the others. Share with the narrowest group that needs the rule: an organization ARN shares it with every account in the organization.
    - `allow_external_principals` - (Optional) Allow sharing with accounts outside your AWS organization. Defaults to `false`: RAM then accepts only principals in your organization, which must have sharing with AWS Organizations turned on. With `true`, each account outside the organization gets an invitation that it must accept.
    - `name` - (Optional) The name of the resource share. Defaults to `r53_resolver_rule-<name>-<Region abbreviation>`, from the rule's `name` in lowercase with words joined by underscores, such as `r53_resolver_rule-forward_corp-use1` for the name `Forward corp` in us-east-1.
  EOT
  type = object({
    principals                = map(string)
    allow_external_principals = optional(bool, false)
    name                      = optional(string)
  })
  default = null

  validation {
    condition     = var.ram_share == null || try(length(var.ram_share.principals) > 0, false)
    error_message = "ram_share.principals must list at least one principal."
  }

  validation {
    condition = var.ram_share == null || alltrue([
      for p in values(try(var.ram_share.principals, {})) :
      can(regex("^([0-9]{12}|arn:aws[a-z-]*:organizations::[0-9]{12}:(organization/o-[a-z0-9]{10,32}|ou/o-[a-z0-9]{10,32}/ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}))$", p))
    ])
    error_message = "Each ram_share.principals value must be a 12-digit AWS account ID, an organizational unit ARN or an organization ARN."
  }

  validation {
    condition     = var.ram_share == null || try(trimspace(var.ram_share.name), "unset") != ""
    error_message = "ram_share.name must not be empty; leave it out for the default name."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the rule and its resource share in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The outbound endpoint in `resolver_endpoint_id`, and the VPCs that use the rule, must be in the same Region.
  EOT
  type        = string
  default     = null
}

variable "resolver_endpoint_id" {
  description = <<-EOT
    The ID of the outbound Resolver endpoint that forwards the queries, such as `rslvr-out-0123456789abcdef0`. Required for a `FORWARD` rule, and must be left `null` for a `SYSTEM` rule. Defaults to `null`. It can be changed without replacing the rule. The endpoint must support each protocol used in `target_ips`, or AWS rejects the rule.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.resolver_endpoint_id == null || can(regex("^rslvr-out-[0-9a-z]+$", var.resolver_endpoint_id))
    error_message = "resolver_endpoint_id must be an outbound Resolver endpoint ID, such as rslvr-out-0123456789abcdef0."
  }

  validation {
    condition     = (var.rule_type == "FORWARD") == (var.resolver_endpoint_id != null)
    error_message = "A FORWARD rule needs resolver_endpoint_id, and a SYSTEM rule must not set it."
  }
}

variable "rule_type" {
  description = <<-EOT
    What the rule does with matching queries:

    - `FORWARD` - (Default) Forward them through the outbound endpoint in `resolver_endpoint_id` to the DNS servers in `target_ips`, such as servers in your data center.
    - `SYSTEM` - Have the Route 53 Resolver answer them itself. Use it to make an exception to a `FORWARD` rule for a parent domain: a `SYSTEM` rule for `aws.example.com` keeps those queries in AWS while a `FORWARD` rule sends the rest of `example.com` elsewhere.

    Changing it replaces the rule.
  EOT
  type        = string
  default     = "FORWARD"
  nullable    = false

  # AWS creates RECURSIVE rules itself; CreateResolverRule rejects them. DELEGATE rules
  # need a delegation record, which the AWS provider does not support.
  validation {
    condition     = contains(["FORWARD", "SYSTEM"], var.rule_type)
    error_message = "rule_type must be FORWARD or SYSTEM."
  }
}

variable "target_ips" {
  description = <<-EOT
    The DNS servers a `FORWARD` rule sends queries to. Required, at least one, for a `FORWARD` rule; must be empty for a `SYSTEM` rule. Defaults to `[]`. The list can be changed without replacing the rule. Each server is an object:

    - `ip` - (Optional) An IPv4 address, such as `10.0.0.2`. Set exactly one of `ip` and `ipv6`, and use the same one in every entry: AWS rejects a rule with both IPv4 and IPv6 servers.
    - `ipv6` - (Optional) An IPv6 address. The outbound endpoint must be of type `IPV6` or `DUALSTACK`, or AWS rejects the rule.
    - `port` - (Optional) The port, 1 to 65535. Defaults to `53`.
    - `protocol` - (Optional) `Do53` (plain DNS), `DoH` (DNS over HTTPS) or `DoH-FIPS` (DNS over HTTPS with FIPS-validated encryption). Defaults to `Do53`. The outbound endpoint must support it, or AWS rejects the rule; DoH servers usually listen on port 443.

    AWS also rejects addresses it treats as reserved. In testing these included link-local IPv4 addresses such as `169.254.169.253`, IPv6 unique local addresses (`fd00::/8`) and the IPv6 documentation range (`2001:db8::/32`).
  EOT
  type = list(object({
    ip       = optional(string)
    ipv6     = optional(string)
    port     = optional(number, 53)
    protocol = optional(string, "Do53")
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for t in var.target_ips : (t.ip == null) != (t.ipv6 == null)])
    error_message = "Each target_ips entry must set exactly one of ip and ipv6."
  }

  validation {
    condition = alltrue([
      for t in var.target_ips : t.ip == null || can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$", t.ip))
    ])
    error_message = "Each target_ips[*].ip must be an IPv4 address, such as 10.0.0.2, without a port."
  }

  validation {
    condition     = alltrue([for t in var.target_ips : t.ipv6 == null || (can(cidrhost("${t.ipv6}/128", 0)) && try(strcontains(t.ipv6, ":"), false))])
    error_message = "Each target_ips[*].ipv6 must be an IPv6 address, without a port."
  }

  validation {
    condition     = alltrue([for t in var.target_ips : t.port == floor(t.port) && t.port >= 1 && t.port <= 65535])
    error_message = "Each target_ips[*].port must be a whole number from 1 to 65535."
  }

  validation {
    condition     = alltrue([for t in var.target_ips : contains(["Do53", "DoH", "DoH-FIPS"], t.protocol)])
    error_message = "Each target_ips[*].protocol must be Do53, DoH or DoH-FIPS."
  }

  # Route 53 Resolver: "target IP addresses can only have one type of Ip Address".
  validation {
    condition     = alltrue([for t in var.target_ips : t.ip != null]) || alltrue([for t in var.target_ips : t.ipv6 != null])
    error_message = "target_ips must be all IPv4 (ip) or all IPv6 (ipv6); AWS rejects a rule with both."
  }

  validation {
    condition     = var.rule_type == "FORWARD" ? length(var.target_ips) > 0 : length(var.target_ips) == 0
    error_message = "A FORWARD rule needs at least one entry in target_ips, and a SYSTEM rule must not have any."
  }
}

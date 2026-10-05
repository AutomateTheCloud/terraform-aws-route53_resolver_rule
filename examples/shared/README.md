# Shared rule

A forwarding rule for `corp.example.org`, shared through AWS Resource Access Manager (RAM) with one other account in your AWS organization. That account can then associate the rule with its own VPCs, whose queries for `corp.example.org` then go through your outbound endpoint to your DNS servers. It cannot change or delete the rule.

The example shares with one account rather than the whole organization: share a rule only with the accounts that need it. `allow_external_principals` is left at `false`, so the share is refused for an account outside your organization. Sharing within an organization needs sharing with AWS Organizations turned on in the management account; see [Sharing the rule with other accounts](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule#sharing-the-rule-with-other-accounts).

## Run it

```shell
terraform init
terraform apply \
  -var 'resolver_endpoint_id=rslvr-out-0123456789abcdef0' \
  -var 'dns_servers=["192.0.2.10","192.0.2.11"]' \
  -var 'workload_account_id=111111111111'
```

In the other account, associate the rule with a VPC, using the `resolver_rule_id` output:

```hcl
resource "aws_route53_resolver_rule_association" "corp" {
  resolver_rule_id = "rslvr-rr-0123456789abcdef0"
  vpc_id           = "vpc-0123456789abcdef0"
}
```

Remove that association first, then run `terraform destroy` here with the same `-var` options: Route 53 Resolver will not delete a rule that is still associated with a VPC.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_dns_servers"></a> [dns_servers](#input_dns_servers)

Description: IPv4 addresses of the DNS servers that answer for corp.example.org, such as ["192.0.2.10", "192.0.2.11"]

Type: `list(string)`

#### <a name="input_resolver_endpoint_id"></a> [resolver_endpoint_id](#input_resolver_endpoint_id)

Description: ID of an outbound Resolver endpoint in us-east-1, such as rslvr-out-0123456789abcdef0

Type: `string`

#### <a name="input_workload_account_id"></a> [workload_account_id](#input_workload_account_id)

Description: ID of the AWS account to share the rule with, in the same AWS organization, such as 111111111111

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_resolver_rule_id"></a> [resolver_rule_id](#output_resolver_rule_id)

Description: ID of the rule, for the other account's aws_route53_resolver_rule_association

#### <a name="output_resource_share_arn"></a> [resource_share_arn](#output_resource_share_arn)

Description: ARN of the Resource Access Manager share
<!-- END_TF_DOCS -->

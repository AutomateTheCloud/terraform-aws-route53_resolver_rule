# Basic rule

A rule that forwards queries for one domain, such as `corp.example.org`, through an existing outbound Resolver endpoint to DNS servers in your network, created with only the module's required inputs. The example also associates the rule with a VPC, because a rule does nothing until it is associated with one. The output is the rule's ID, for associating it with more VPCs.

The endpoint, its security group and the network path to the DNS servers must already work; see [Forwarding needs a working path](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule#forwarding-needs-a-working-path).

## Run it

```shell
terraform init
terraform apply \
  -var 'domain_name=corp.example.org' \
  -var 'resolver_endpoint_id=rslvr-out-0123456789abcdef0' \
  -var 'dns_servers=["192.0.2.10","192.0.2.11"]' \
  -var 'vpc_id=vpc-0123456789abcdef0'
```

Remove it with `terraform destroy` and the same `-var` options. Replace the values with your own; the ones above are placeholders. The VPC can have only one rule for a given domain name, so the apply fails if it already has one for `domain_name`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_dns_servers"></a> [dns_servers](#input_dns_servers)

Description: IPv4 addresses of the DNS servers that answer for the domain, such as ["192.0.2.10", "192.0.2.11"]

Type: `list(string)`

#### <a name="input_domain_name"></a> [domain_name](#input_domain_name)

Description: The domain name to forward, such as corp.example.org

Type: `string`

#### <a name="input_resolver_endpoint_id"></a> [resolver_endpoint_id](#input_resolver_endpoint_id)

Description: ID of an outbound Resolver endpoint in us-east-1, such as rslvr-out-0123456789abcdef0

Type: `string`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of a VPC in us-east-1 to use the rule in, such as vpc-0123456789abcdef0

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_resolver_rule_id"></a> [resolver_rule_id](#output_resolver_rule_id)

Description: ID of the rule, for associating it with more VPCs
<!-- END_TF_DOCS -->

# Complete

Most of the module's inputs, in two rules created in a Region other than the provider's and associated with one VPC there:

- A `FORWARD` rule for `corp.example.org` to three DNS servers: one on port 53, one on port 5353, and one over DNS over HTTPS (DoH) on port 443. It is shared through AWS Resource Access Manager with one organizational unit, under a share name chosen instead of the default.
- A `SYSTEM` rule for `aws.corp.example.org`. The Resolver uses the rule with the most specific domain name, so queries for that subdomain are answered in AWS as usual, for example from a private hosted zone, instead of being forwarded.

The outbound endpoint must support the `Do53` and `DoH` protocols, and its security group must allow outbound traffic to ports 53, 5353 and 443. The DNS server addresses are documentation addresses; replace them with your own in `main.tf`.

## Run it

```shell
terraform init
terraform apply \
  -var 'region=us-west-2' \
  -var 'resolver_endpoint_id=rslvr-out-0123456789abcdef0' \
  -var 'vpc_id=vpc-0123456789abcdef0' \
  -var 'workloads_ou_arn=arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111'
```

Remove it with `terraform destroy` and the same `-var` options, after removing any association the organizational unit's accounts made with the forwarding rule.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_region"></a> [region](#input_region)

Description: The Region to create the rules in, such as us-west-2. The endpoint and the VPC must be in it.

Type: `string`

#### <a name="input_resolver_endpoint_id"></a> [resolver_endpoint_id](#input_resolver_endpoint_id)

Description: ID of an outbound Resolver endpoint in var.region that supports Do53 and DoH, such as rslvr-out-0123456789abcdef0

Type: `string`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of a VPC in var.region to use the rules in, such as vpc-0123456789abcdef0

Type: `string`

#### <a name="input_workloads_ou_arn"></a> [workloads_ou_arn](#input_workloads_ou_arn)

Description: ARN of the organizational unit to share the forwarding rule with, such as arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_forward_rule_id"></a> [forward_rule_id](#output_forward_rule_id)

Description: ID of the forwarding rule, for associating it with more VPCs

#### <a name="output_resource_share_arn"></a> [resource_share_arn](#output_resource_share_arn)

Description: ARN of the Resource Access Manager share for the forwarding rule

#### <a name="output_system_rule_id"></a> [system_rule_id](#output_system_rule_id)

Description: ID of the SYSTEM rule
<!-- END_TF_DOCS -->

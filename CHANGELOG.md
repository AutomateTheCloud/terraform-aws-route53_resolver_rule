# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Fixed

- `metadata.ram_resource_share` no longer has `permission_arns`. AWS fills it in when the rule is added to the share, after the share is saved, so the first plan after sharing a rule showed the output changing.

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- A Route 53 Resolver rule that forwards queries for a domain through an outbound endpoint to DNS servers you choose, or a `SYSTEM` rule that makes an exception for a subdomain.
- DNS servers on IPv4 or IPv6, on any port, over plain DNS or DNS over HTTPS.
- Sharing through AWS Resource Access Manager with the accounts, organizational units or organization you list, limited to your own AWS organization unless you allow more.
- Validation of the inputs at plan time, including the combinations AWS rejects at apply.
- `region`, to create the rule in another Region without configuring another provider.
- A `metadata` output with everything the module created, including the rule's ID for VPC associations.
- Offline tests, and examples for a basic rule, a rule shared with one account, and a complete configuration.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule/releases/tag/v1.0.0

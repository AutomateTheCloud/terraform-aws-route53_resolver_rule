# Security

## Reporting a vulnerability

Report security problems privately, not in a public issue. On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**. Only the maintainers can see the report.

Include what you found, how to reproduce it, and what an attacker could do with it.

## What counts

A security problem in this module is anything that makes a rule more exposed than its inputs say it should be: for example, a rule shared with a principal the caller did not list, sharing outside the caller's AWS organization without `allow_external_principals`, queries forwarded to a server the caller did not list, or a validation that lets an unsafe value through.

## Supported versions

Fixes are made to the latest release.

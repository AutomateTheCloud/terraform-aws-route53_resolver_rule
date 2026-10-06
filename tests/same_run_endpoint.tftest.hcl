# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

# The outbound endpoint, the target addresses and the RAM principal are created in the
# same run as the rule, so their values are unknown at plan time. The module must still
# plan.
run "same_run_dependencies" {
  command = plan
  module {
    source = "./tests/fixtures/same_run_endpoint"
  }
}

data "aws_organizations_organization" "this" {
  count    = local.guardrails_enable
  provider = aws.org

  lifecycle {
    precondition {
      condition     = length(local.duplicated_policy_names) == 0
      error_message = "Policy names must be unique across service_control_policies and custom_policies. Duplicated: ${jsonencode(local.duplicated_policy_names)}."
    }
  }
}

# First-level OUs (direct children of the organization root), used to resolve OU names in targets.
data "aws_organizations_organizational_units" "root" {
  count    = local.guardrails_enable
  provider = aws.org

  parent_id = data.aws_organizations_organization.this[0].roots[0].id
}

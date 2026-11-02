# Renders one minified SCP document from the built-in guardrail catalog.
# Key: policy name (guardrails_parameters.service_control_policies).
module "guardrails_scp" {
  source   = "./modules/aws/terraform-aws-guardrails-scp"
  for_each = local.scp_parameters

  providers = { aws = aws.org }

  guardrails            = try(each.value.guardrails, {})
  exempt_principal_arns = try(each.value.exempt_principal_arns, null) != null ? tolist(each.value.exempt_principal_arns) : tolist(local.exempt_principal_arns)
}

# One organization policy (catalog SCP or custom policy) plus its attachments.
# Key: policy name; attachments inside are keyed by the target as written.
module "organizations_policy" {
  source   = "./modules/aws/terraform-aws-organizations-policy"
  for_each = local.policies

  providers = { aws = aws.org }

  name        = each.key
  description = try(each.value.description, var.guardrails_defaults.description, "Managed by Terraform - GoCloud guardrails (${each.key})")
  type        = each.value.type
  content     = each.value.content
  tags        = merge(local.common_tags, try(each.value.tags, var.guardrails_defaults.tags, null))

  targets = {
    for attachment in values(local.attachments) :
    attachment.target => attachment.target_id
    if attachment.policy_name == each.key
  }
}

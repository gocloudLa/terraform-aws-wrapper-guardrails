locals {
  guardrails_enable = try(var.guardrails_parameters.enable, false) ? 1 : 0

  # Principals exempted from every guardrail that supports exemptions (policy and guardrail levels can override).
  exempt_principal_arns = try(var.guardrails_parameters.exempt_principal_arns, var.guardrails_defaults.exempt_principal_arns, [
    "arn:aws:iam::*:role/OrganizationAccountAccessRole",
    "arn:aws:iam::*:role/stacksets-exec-*",
  ])

  # Raw policy entries, empty when the wrapper is disabled. Key: policy name.
  scp_parameters    = { for k, v in try(var.guardrails_parameters.service_control_policies, {}) : k => v if local.guardrails_enable == 1 }
  custom_parameters = { for k, v in try(var.guardrails_parameters.custom_policies, {}) : k => v if local.guardrails_enable == 1 }

  # Policy names are the aws_organizations_policy names, so they must be unique across both maps.
  duplicated_policy_names = setintersection(keys(local.scp_parameters), keys(local.custom_parameters))

  # Every managed policy (catalog SCPs rendered by module.guardrails_scp + custom policies) with its type and content.
  # Key: policy name.
  policies = merge(
    {
      for k, v in local.scp_parameters :
      k => merge(v, {
        type    = "SERVICE_CONTROL_POLICY"
        content = module.guardrails_scp[k].json
      })
    },
    {
      for k, v in local.custom_parameters :
      k => merge(v, {
        type    = try(v.type, var.guardrails_defaults.type, "SERVICE_CONTROL_POLICY")
        content = try(v.content, null)
      })
    },
  )
  # output "debug_policies" { value = local.policies }

  /*----------------------------------------------------------------------*/
  /* Targets resolution                                                   */
  /*----------------------------------------------------------------------*/

  organization_root_id = try(data.aws_organizations_organization.this[0].roots[0].id, null)

  # First-level OU name -> OU id.
  ou_ids_by_name = {
    for ou in try(data.aws_organizations_organizational_units.root[0].children, []) :
    ou.name => ou.id
  }

  # Account name -> account id. Names shared by several accounts are ambiguous and left out (use the account id).
  account_ids_by_name = {
    for name, ids in { for account in try(data.aws_organizations_organization.this[0].accounts, []) : account.name => account.id... } :
    name => ids[0] if length(ids) == 1
  }

  # One entry per policy/target pair. Target resolution order: "root" -> raw id (r-*, ou-*, 12 digits) -> first-level OU
  # name -> account name; unresolved targets keep target_id = null and fail on the attachment precondition.
  # Key: "<policy-name>-<target-as-written>".
  attachments_tmp = [
    for policy_name, policy in local.policies :
    [
      for target in distinct(try(policy.targets, [])) :
      {
        "${policy_name}-${target}" = {
          policy_name = policy_name
          policy_type = policy.type
          target      = target
          target_id = (
            target == "root" ? local.organization_root_id :
            can(regex("^(r-|ou-)|^[0-9]{12}$", target)) ? target :
            try(local.ou_ids_by_name[target], local.account_ids_by_name[target], null)
          )
        }
      }
    ]
  ]

  attachments = merge(flatten(local.attachments_tmp)...)
  # output "debug_attachments" { value = local.attachments }

  # Target as written -> resolved target id (all policies).
  targets = merge([for attachment in values(local.attachments) : { (attachment.target) = attachment.target_id }]...)
  # output "debug_targets" { value = local.targets }

  # SCP names managed by this module per resolved target id. AWS allows 5 SCPs per target including FullAWSAccess.
  scp_names_by_target_id = {
    for attachment in values(local.attachments) :
    attachment.target_id => attachment.policy_name...
    if attachment.policy_type == "SERVICE_CONTROL_POLICY" && attachment.target_id != null
  }

  scp_overloaded_targets = { for target_id, names in local.scp_names_by_target_id : target_id => names if length(names) > 4 }
  # output "debug_scp_overloaded_targets" { value = local.scp_overloaded_targets }
}

output "enabled" {
  description = "Whether guardrails resources were created (guardrails_parameters.enable)."
  value       = local.guardrails_enable == 1
}

output "policy_ids" {
  description = "Organization policy IDs by policy name."
  value       = { for name, policy in module.organizations_policy : name => policy.id }
}

output "policy_arns" {
  description = "Organization policy ARNs by policy name."
  value       = { for name, policy in module.organizations_policy : name => policy.arn }
}

output "attachments" {
  description = "Policy attachments: \"<policy-name>-<target>\" => resolved target ID."
  value       = { for key, attachment in local.attachments : key => attachment.target_id }

  precondition {
    condition     = length(local.scp_overloaded_targets) == 0
    error_message = "More than 4 SERVICE_CONTROL_POLICY attachments managed by this module on a target (AWS limit is 5 including FullAWSAccess): ${jsonencode(local.scp_overloaded_targets)}."
  }
}

output "targets" {
  description = "Targets as written in guardrails_parameters => resolved Organizations target ID."
  value       = local.targets
}

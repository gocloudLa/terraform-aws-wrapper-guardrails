output "enabled" {
  description = "Whether the wrapper created guardrails resources."
  value       = module.wrapper_guardrails.enabled
}

output "policy_ids" {
  value = module.wrapper_guardrails.policy_ids
}

output "policy_arns" {
  value = module.wrapper_guardrails.policy_arns
}

output "attachments" {
  value = module.wrapper_guardrails.attachments
}

output "targets" {
  value = module.wrapper_guardrails.targets
}

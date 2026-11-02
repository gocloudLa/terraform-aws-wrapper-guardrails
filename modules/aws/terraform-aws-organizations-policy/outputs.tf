output "id" {
  description = "Organization policy ID."
  value       = aws_organizations_policy.this.id
}

output "arn" {
  description = "Organization policy ARN."
  value       = aws_organizations_policy.this.arn
}

output "attachments" {
  description = "Target as written => attached target ID."
  value       = { for target, attachment in aws_organizations_policy_attachment.this : target => attachment.target_id }
}

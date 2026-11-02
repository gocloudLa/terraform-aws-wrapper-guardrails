output "json" {
  description = "Minified SCP document (whitespace counts toward the 5120-character SCP limit)."
  value       = jsonencode(jsondecode(data.aws_iam_policy_document.this.json))
}

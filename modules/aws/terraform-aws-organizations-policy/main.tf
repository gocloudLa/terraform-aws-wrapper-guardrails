resource "aws_organizations_policy" "this" {
  name        = var.name
  description = var.description
  type        = var.type
  content     = var.content

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.type != "SERVICE_CONTROL_POLICY" || length(var.content) <= 5120
      error_message = "Policy \"${var.name}\" is ${length(var.content)} characters long; SERVICE_CONTROL_POLICY content must be <= 5120 characters. Split its guardrails across several policies."
    }
  }
}

# Key: target as written in guardrails_parameters ("root", OU/account name or ID).
resource "aws_organizations_policy_attachment" "this" {
  for_each = var.targets

  policy_id = aws_organizations_policy.this.id
  target_id = each.value

  lifecycle {
    precondition {
      condition     = each.value != null
      error_message = "Target \"${each.key}\" of policy \"${var.name}\" could not be resolved. Use \"root\", a root/OU/account ID (r-*, ou-*, 12 digits), a first-level OU name or a unique account name."
    }
  }
}

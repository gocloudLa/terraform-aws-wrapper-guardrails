variable "guardrails" {
  type        = any
  description = "Map of guardrail key => guardrail parameters ({} enables a guardrail with its defaults)."

  validation {
    condition     = length(keys(var.guardrails)) > 0
    error_message = "At least one guardrail is required to render a service control policy."
  }

  validation {
    condition = length(setsubtract(keys(var.guardrails), [
      "deny_leave_organization",
      "deny_root_user",
      "region_restriction",
      "protect_security_services",
      "protect_platform_roles",
      "deny_iam_users",
      "protect_s3_account_public_access",
      "protect_backup",
    ])) == 0
    error_message = "Unknown guardrail key(s): ${join(", ", setsubtract(keys(var.guardrails), ["deny_leave_organization", "deny_root_user", "region_restriction", "protect_security_services", "protect_platform_roles", "deny_iam_users", "protect_s3_account_public_access", "protect_backup"]))}. Valid keys: deny_leave_organization, deny_root_user, region_restriction, protect_security_services, protect_platform_roles, deny_iam_users, protect_s3_account_public_access, protect_backup."
  }

  validation {
    condition     = try(var.guardrails.region_restriction, null) == null ? true : length(try(var.guardrails.region_restriction.allowed_regions, [])) > 0
    error_message = "Guardrail region_restriction requires a non-empty allowed_regions list (e.g. allowed_regions = [\"us-east-1\"])."
  }
}

variable "exempt_principal_arns" {
  type        = list(string)
  description = "Principal ARN patterns exempted (ArnNotLike aws:PrincipalArn) from guardrails that support exemptions."
  nullable    = false
}

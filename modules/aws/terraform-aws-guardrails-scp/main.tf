# Member accounts cannot leave the organization. No exemption.
data "aws_iam_policy_document" "deny_leave_organization" {
  count = local.enabled.deny_leave_organization ? 1 : 0

  statement {
    sid       = "DenyLeaveOrganization"
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }
}

# Member account root users cannot perform any action. No exemption.
data "aws_iam_policy_document" "deny_root_user" {
  count = local.enabled.deny_root_user ? 1 : 0

  statement {
    sid       = "DenyRootUser"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }
}

# Deny Regional actions outside allowed_regions (global services excluded through NotAction).
data "aws_iam_policy_document" "region_restriction" {
  count = local.enabled.region_restriction ? 1 : 0

  statement {
    sid         = "DenyNonAllowedRegions"
    effect      = "Deny"
    not_actions = concat(local.region_restriction_not_actions, try(var.guardrails.region_restriction.additional_not_actions, []))
    resources   = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.guardrails.region_restriction.allowed_regions
    }

    dynamic "condition" {
      for_each = length(local.exempt_principal_arns.region_restriction) > 0 ? [1] : []
      content {
        test     = "ArnNotLike"
        variable = "aws:PrincipalArn"
        values   = local.exempt_principal_arns.region_restriction
      }
    }
  }
}

# CloudTrail, GuardDuty, Security Hub, Config and IAM Access Analyzer cannot be disabled or tampered with.
data "aws_iam_policy_document" "protect_security_services" {
  count = local.enabled.protect_security_services ? 1 : 0

  statement {
    sid    = "ProtectSecurityServices"
    effect = "Deny"
    actions = [
      "cloudtrail:DeleteTrail",
      "cloudtrail:StopLogging",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
      "guardduty:DeleteDetector",
      "guardduty:UpdateDetector",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:DisassociateFromAdministratorAccount",
      "guardduty:DisassociateMembers",
      "guardduty:DeleteMembers",
      "guardduty:StopMonitoringMembers",
      "guardduty:DeletePublishingDestination",
      "securityhub:DisableSecurityHub",
      "securityhub:DisassociateFromMasterAccount",
      "securityhub:DisassociateFromAdministratorAccount",
      "securityhub:DisassociateMembers",
      "securityhub:DeleteMembers",
      "securityhub:BatchDisableStandards",
      "config:DeleteConfigurationRecorder",
      "config:StopConfigurationRecorder",
      "config:PutConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "config:PutDeliveryChannel",
      "config:DeleteRetentionConfiguration",
      "access-analyzer:DeleteAnalyzer",
    ]
    resources = ["*"]

    dynamic "condition" {
      for_each = length(local.exempt_principal_arns.protect_security_services) > 0 ? [1] : []
      content {
        test     = "ArnNotLike"
        variable = "aws:PrincipalArn"
        values   = local.exempt_principal_arns.protect_security_services
      }
    }
  }
}

# Platform roles (role_name_patterns) cannot be modified or deleted.
data "aws_iam_policy_document" "protect_platform_roles" {
  count = local.enabled.protect_platform_roles ? 1 : 0

  statement {
    sid    = "ProtectPlatformRoles"
    effect = "Deny"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePermissionsBoundary",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
    ]
    resources = [
      for pattern in try(var.guardrails.protect_platform_roles.role_name_patterns, local.default_platform_role_name_patterns) :
      "arn:aws:iam::*:role/${pattern}"
    ]

    dynamic "condition" {
      for_each = length(local.exempt_principal_arns.protect_platform_roles) > 0 ? [1] : []
      content {
        test     = "ArnNotLike"
        variable = "aws:PrincipalArn"
        values   = local.exempt_principal_arns.protect_platform_roles
      }
    }
  }
}

# IAM users, access keys and console passwords cannot be created (use IAM Identity Center / roles).
data "aws_iam_policy_document" "deny_iam_users" {
  count = local.enabled.deny_iam_users ? 1 : 0

  statement {
    sid    = "DenyIamUsers"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
    ]
    resources = ["*"]

    dynamic "condition" {
      for_each = length(local.exempt_principal_arns.deny_iam_users) > 0 ? [1] : []
      content {
        test     = "ArnNotLike"
        variable = "aws:PrincipalArn"
        values   = local.exempt_principal_arns.deny_iam_users
      }
    }
  }
}

# S3 account-level Block Public Access cannot be changed.
data "aws_iam_policy_document" "protect_s3_account_public_access" {
  count = local.enabled.protect_s3_account_public_access ? 1 : 0

  statement {
    sid       = "ProtectS3AccountPublicAccess"
    effect    = "Deny"
    actions   = ["s3:PutAccountPublicAccessBlock"]
    resources = ["*"]

    dynamic "condition" {
      for_each = length(local.exempt_principal_arns.protect_s3_account_public_access) > 0 ? [1] : []
      content {
        test     = "ArnNotLike"
        variable = "aws:PrincipalArn"
        values   = local.exempt_principal_arns.protect_s3_account_public_access
      }
    }
  }
}

# AWS Backup vaults and recovery points cannot be deleted or have their protection changed.
data "aws_iam_policy_document" "protect_backup" {
  count = local.enabled.protect_backup ? 1 : 0

  statement {
    sid    = "ProtectBackup"
    effect = "Deny"
    actions = [
      "backup:DeleteBackupVault",
      "backup:DeleteBackupVaultAccessPolicy",
      "backup:PutBackupVaultAccessPolicy",
      "backup:DeleteBackupVaultNotifications",
      "backup:PutBackupVaultNotifications",
      "backup:DeleteBackupVaultLockConfiguration",
      "backup:PutBackupVaultLockConfiguration",
      "backup:DeleteRecoveryPoint",
      "backup:UpdateRecoveryPointLifecycle",
    ]
    resources = ["*"]

    dynamic "condition" {
      for_each = length(local.exempt_principal_arns.protect_backup) > 0 ? [1] : []
      content {
        test     = "ArnNotLike"
        variable = "aws:PrincipalArn"
        values   = local.exempt_principal_arns.protect_backup
      }
    }
  }
}

# Single SCP document combining the enabled guardrails (one statement each, stable Sids).
data "aws_iam_policy_document" "this" {
  source_policy_documents = concat(
    data.aws_iam_policy_document.deny_leave_organization[*].json,
    data.aws_iam_policy_document.deny_root_user[*].json,
    data.aws_iam_policy_document.region_restriction[*].json,
    data.aws_iam_policy_document.protect_security_services[*].json,
    data.aws_iam_policy_document.protect_platform_roles[*].json,
    data.aws_iam_policy_document.deny_iam_users[*].json,
    data.aws_iam_policy_document.protect_s3_account_public_access[*].json,
    data.aws_iam_policy_document.protect_backup[*].json,
  )
}

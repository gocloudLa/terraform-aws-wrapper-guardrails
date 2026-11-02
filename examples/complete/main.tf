module "wrapper_guardrails" {
  source = "../../"

  providers = {
    aws.org = aws # Organization Management Account
  }

  metadata = local.metadata

  guardrails_parameters = {
    enable = true # Default: false

    # -------------------------------------------------------------------------
    # Top-level — principals exempted from every guardrail that supports exemptions.
    # -------------------------------------------------------------------------
    # exempt_principal_arns = [
    #   "arn:aws:iam::*:role/OrganizationAccountAccessRole",
    #   "arn:aws:iam::*:role/stacksets-exec-*",
    # ]

    # -------------------------------------------------------------------------
    # service_control_policies — SCPs built from the guardrail catalog. Key: policy name.
    # targets: "root", first-level OU names, account names, or r-* / ou-* / account IDs.
    # -------------------------------------------------------------------------
    service_control_policies = {
      "baseline" = {
        # description           = null # default: "Managed by Terraform - GoCloud guardrails (baseline)"
        # exempt_principal_arns = null # overrides the top-level list for this policy
        # tags                  = {}
        targets = ["root"]

        guardrails = {
          deny_leave_organization = {}
          deny_root_user          = {}
          region_restriction = {
            allowed_regions = ["us-east-2", "us-east-1"]
            # additional_not_actions = []
          }
        }
      }

      "workloads" = {
        targets = ["Workload", "ou-xxxx-xxxxxxxx", "123456789012"]

        guardrails = {
          protect_security_services = {}
          protect_platform_roles = {
            # role_name_patterns = ["OrganizationAccountAccessRole", "stacksets-exec-*"]
            role_name_patterns = ["OrganizationAccountAccessRole", "stacksets-exec-*", "platform-*"] # Default: ["OrganizationAccountAccessRole", "stacksets-exec-*"]
          }
          deny_iam_users = {
            exempt_principal_arns = ["arn:aws:iam::*:role/break-glass"] # Default: policy / top-level list
          }
          protect_s3_account_public_access = {}
          protect_backup                   = {}
        }
      }
    }

    # -------------------------------------------------------------------------
    # custom_policies — any organization policy type with your own content. Key: policy name.
    # -------------------------------------------------------------------------
    custom_policies = {
      "sandbox-deny-marketplace" = {
        # type        = "SERVICE_CONTROL_POLICY"
        # description = null
        # tags        = {}
        targets = ["Sandbox"]
        content = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Sid      = "DenyMarketplaceSubscriptions"
              Effect   = "Deny"
              Action   = ["aws-marketplace:Subscribe"]
              Resource = "*"
            },
          ]
        })
      }

      # Requires RESOURCE_CONTROL_POLICY in the organization enabled_policy_types.
      # "rcp-enforce-tls" = {
      #   type    = "RESOURCE_CONTROL_POLICY"
      #   targets = ["root"]
      #   content = file("policies/rcp-enforce-tls.json")
      # }
    }
  }

  guardrails_defaults = {}
}

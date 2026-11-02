# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform Guardrails Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-guardrails/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-guardrails.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-guardrails.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-guardrails/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
Wrapper for AWS Organizations preventive guardrails: builds Service Control Policies from a built-in, parameterized
catalog of security guardrails, manages custom organization policies of any type, and attaches them to the root,
organizational units or accounts referenced by name or ID.


### ✨ Features

- 🧱 [Organization baseline guardrails](#organization-baseline-guardrails) - Keep accounts inside the organization, block the root user and restrict Regions.

- 🛡️ [Security and platform protection guardrails](#security-and-platform-protection-guardrails) - Prevent tampering with security services, platform roles, S3 Block Public Access and AWS Backup, and creation of IAM users.

- 🎯 [Targets by name or ID](#targets-by-name-or-id) - Attach policies to the root, first-level OUs or accounts using names or raw IDs.

- 🧩 [Custom organization policies](#custom-organization-policies) - Bring your own policy content for any Organizations policy type (SCP, RCP, declarative, tag, backup, ...).

- 📏 [Size and quota validations](#size-and-quota-validations) - Fail at plan time before AWS rejects an oversized SCP or a target with too many SCPs.




## 🚀 Quick Start
```hcl
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
  }
}
```


## 🔧 Additional Features Usage

### Organization baseline guardrails
Each `service_control_policies` entry renders one minified SCP from the guardrails it lists, one statement per guardrail with a stable Sid.
`deny_leave_organization` and `deny_root_user` have no exemptions. `region_restriction` denies Regional actions outside
`allowed_regions` while global services (IAM, Organizations, STS, Route 53, CloudFront, billing, ...) stay allowed through `NotAction`,
based on the AWS Control Tower Region deny control; extend the list with `additional_not_actions`.


<details><summary>Baseline SCP on the organization root</summary>

```hcl
guardrails_parameters = {
  enable = true

  service_control_policies = {
    "baseline" = {
      targets = ["root"]

      guardrails = {
        deny_leave_organization = {}
        deny_root_user          = {}
        region_restriction = {
          allowed_regions = ["us-east-2", "us-east-1"]
        }
      }
    }
  }
}
```


</details>


### Security and platform protection guardrails
`protect_security_services` denies disabling CloudTrail, GuardDuty, Security Hub, Config and IAM Access Analyzer.
`protect_platform_roles` protects the roles matching `role_name_patterns`; `deny_iam_users`, `protect_s3_account_public_access`
and `protect_backup` cover IAM users/access keys, account-level S3 Block Public Access and backup vaults/recovery points.
These guardrails exempt `exempt_principal_arns` (`ArnNotLike` on `aws:PrincipalArn`), resolved guardrail → policy → top-level → defaults.


<details><summary>Workload protections with a guardrail-level exemption</summary>

```hcl
guardrails_parameters = {
  enable = true

  service_control_policies = {
    "workloads" = {
      targets = ["Workload", "Sandbox"]

      guardrails = {
        protect_security_services = {}
        protect_platform_roles    = {}
        deny_iam_users = {
          exempt_principal_arns = ["arn:aws:iam::*:role/break-glass"] # Default: policy / top-level list
        }
        protect_s3_account_public_access = {}
        protect_backup                   = {}
      }
    }
  }
}
```


</details>


### Targets by name or ID
Each target resolves to an Organizations target ID: `"root"` uses the organization root, `r-*`, `ou-*` and 12-digit values pass through,
any other value is looked up as a first-level OU name and then as an account name. Unknown or ambiguous names fail the plan
with a clear message instead of being dropped. Attachments are keyed by `"<policy-name>-<target>"`, so adding targets never recreates others.


<details><summary>Mix names and IDs</summary>

```hcl
guardrails_parameters = {
  enable = true

  service_control_policies = {
    "workloads" = {
      targets = ["Workload", "ou-xxxx-xxxxxxxx", "123456789012"]

      guardrails = {
        protect_security_services = {}
      }
    }
  }
}
```


</details>


### Custom organization policies
`custom_policies` entries become an `aws_organizations_policy` with the given `type` (default `SERVICE_CONTROL_POLICY`) and `content`,
attached to `targets` with the same resolution rules. Policy names must be unique across `service_control_policies` and `custom_policies`.


<details><summary>Custom SCP and RCP</summary>

```hcl
guardrails_parameters = {
  enable = true

  custom_policies = {
    "sandbox-deny-marketplace" = {
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

    "rcp-enforce-tls" = {
      type    = "RESOURCE_CONTROL_POLICY" # Default: "SERVICE_CONTROL_POLICY"
      targets = ["root"]
      content = file("policies/rcp-enforce-tls.json")
    }
  }
}
```


</details>


### Size and quota validations
Catalog SCPs are minified because whitespace counts toward the 5120-character SCP limit; any SERVICE_CONTROL_POLICY longer than
5120 characters fails with its actual length. The wrapper also fails when more than 4 module-managed SCPs target the same root,
OU or account (AWS allows 5 including `FullAWSAccess`), when a guardrail key is unknown, or when `region_restriction` has no `allowed_regions`.





## 📑 Inputs
| Name                                                 | Description                                                                                                             | Type           | Default                                                                                         | Required       |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------- | -------------- |
| enable                                               | When `true`, create the organization policies and attachments (`count` gate).                                           | `bool`         | `false`                                                                                         | no             |
| exempt_principal_arns                                | Principal ARN patterns exempted (`ArnNotLike` on `aws:PrincipalArn`) from every guardrail that supports exemptions.     | `list(string)` | `["arn:aws:iam::*:role/OrganizationAccountAccessRole", "arn:aws:iam::*:role/stacksets-exec-*"]` | no             |
| service_control_policies                             | Map keyed by policy name (`name` on `aws_organizations_policy`); each entry renders one SCP from the guardrail catalog. | `map`          | `{}`                                                                                            | no             |
| service_control_policies.description                 | `description` on `aws_organizations_policy`.                                                                            | `string`       | `` `Managed by Terraform - GoCloud guardrails ({policy-name})` ``                               | no             |
| service_control_policies.exempt_principal_arns       | Overrides the top-level `exempt_principal_arns` for this policy.                                                        | `list(string)` | `null`                                                                                          | no             |
| service_control_policies.tags                        | Tags merged over `metadata` common tags.                                                                                | `map`          | `{}`                                                                                            | no             |
| service_control_policies.targets                     | `"root"`, first-level OU names, account names, or `r-*` / `ou-*` / account IDs.                                         | `list(string)` | `[]`                                                                                            | no             |
| service_control_policies.guardrails                  | Map of catalog guardrail key => parameters (`{}` enables it with defaults); at least one required.                      | `map`          | —                                                                                               | yes            |
| guardrails.deny_leave_organization                   | Deny `organizations:LeaveOrganization` (no exemption).                                                                  | `map`          | `null`                                                                                          | no             |
| guardrails.deny_root_user                            | Deny every action for member account root users (no exemption).                                                         | `map`          | `null`                                                                                          | no             |
| guardrails.region_restriction.allowed_regions        | Regions where Regional actions are allowed (`aws:RequestedRegion`).                                                     | `list(string)` | —                                                                                               | yes (when set) |
| guardrails.region_restriction.additional_not_actions | Extra actions appended to the global-services `NotAction` list.                                                         | `list(string)` | `[]`                                                                                            | no             |
| guardrails.protect_security_services                 | Deny disabling CloudTrail, GuardDuty, Security Hub, Config and IAM Access Analyzer.                                     | `map`          | `null`                                                                                          | no             |
| guardrails.protect_platform_roles.role_name_patterns | Role name patterns whose IAM roles cannot be modified or deleted.                                                       | `list(string)` | `["OrganizationAccountAccessRole", "stacksets-exec-*"]`                                         | no             |
| guardrails.deny_iam_users                            | Deny `iam:CreateUser`, `iam:CreateAccessKey` and `iam:CreateLoginProfile`.                                              | `map`          | `null`                                                                                          | no             |
| guardrails.protect_s3_account_public_access          | Deny `s3:PutAccountPublicAccessBlock`.                                                                                  | `map`          | `null`                                                                                          | no             |
| guardrails.protect_backup                            | Deny deleting or weakening AWS Backup vaults and recovery points.                                                       | `map`          | `null`                                                                                          | no             |
| guardrails.<key>.exempt_principal_arns               | Overrides the policy-level exemption list for one guardrail (exemptible guardrails only).                               | `list(string)` | `null`                                                                                          | no             |
| custom_policies                                      | Map keyed by policy name (unique across both policy maps) with custom policy content.                                   | `map`          | `{}`                                                                                            | no             |
| custom_policies.type                                 | `type` on `aws_organizations_policy` (any Organizations policy type).                                                   | `string`       | `"SERVICE_CONTROL_POLICY"`                                                                      | no             |
| custom_policies.content                              | Policy document (JSON), e.g. `jsonencode({...})` or `file(...)`.                                                        | `string`       | —                                                                                               | yes            |
| custom_policies.description                          | `description` on `aws_organizations_policy`.                                                                            | `string`       | `` `Managed by Terraform - GoCloud guardrails ({policy-name})` ``                               | no             |
| custom_policies.tags                                 | Tags merged over `metadata` common tags.                                                                                | `map`          | `{}`                                                                                            | no             |
| custom_policies.targets                              | Same target syntax as `service_control_policies.targets`.                                                               | `list(string)` | `[]`                                                                                            | no             |







## ⚠️ Important Notes
- ℹ️ **Management account:** SCPs never affect the management account; guardrails only apply to member accounts.
- 🔒 **Lockout risk:** SCPs attached to the OU where Terraform or the SSO administrators run can block the pipeline itself. Exempt the automation roles in `exempt_principal_arns`, or do not attach security-service guardrails to the Security OU.
- ⚠️ **Policy types:** `RESOURCE_CONTROL_POLICY`, `DECLARATIVE_POLICY_EC2` and other non-SCP types must be enabled in the organization `enabled_policy_types` before using them in `custom_policies`.
- ⚠️ **Quotas:** A target holds at most 5 SCPs including `FullAWSAccess`, and each SCP is limited to 5120 characters; split guardrails across policies when needed.
- ⚠️ **Rollout:** Attach new guardrails to a Sandbox OU first and validate workloads before moving them to production OUs or the root.
- ℹ️ **Service-linked roles:** SCPs do not restrict service-linked roles, so they need no exemption.



---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 
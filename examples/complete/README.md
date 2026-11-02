# Complete example 🚀

Runnable root module wiring for terraform-aws-wrapper-guardrails; parameters follow the same variable pattern as other GoCloud wrappers (metadata, guardrails_parameters, guardrails_defaults).

## 🔧 What's Included

### Analysis of Terraform Configuration

#### Main Purpose
Demonstrate catalog SCPs, target resolution by name or ID and a custom policy from the Organizations management account; replace the placeholder OU/account IDs before applying.

#### Key Features Demonstrated
- **metadata** — Defined in `metadata.tf` (same pattern as other examples; optional `variable "metadata"` remains commented in `variables.tf`).
- **guardrails_parameters.service_control_policies** — `baseline` on the root (leave organization, root user, Region restriction) and `workloads` on OUs/accounts (security services, platform roles, IAM users, S3 public access, Backup).
- **guardrails_parameters.custom_policies** — Arbitrary policy content of any Organizations policy type (commented RCP example).
- **guardrails_defaults** — Same pattern as other wrappers (`tags`, `exempt_principal_arns`, `type`, `description` fallbacks).
- **Non-defaults in the example** — Literals with `# Default: …` comments.
- **Providers** — Single `aws` mapped to `aws.org`; uncomment the alias in providers.tf for a dedicated management account provider.

## 🚀 Quick Start

```bash
terraform init
terraform plan
terraform apply
```

## 🔒 Security Notes

⚠️ **Production Considerations**: 
- This example may include configurations that are not suitable for production environments
- Review and customize security settings, access controls, and resource configurations
- Ensure compliance with your organization's security policies
- Consider implementing proper monitoring, logging, and backup strategies

## 📖 Documentation

For detailed module documentation and additional examples, see the main [README.md](../../README.md) file. 
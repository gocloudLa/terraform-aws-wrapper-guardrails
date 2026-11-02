provider "aws" {
  region = local.metadata.aws_region
}

# Multi-account: run against the Organizations management account, e.g.
# providers = { aws.org = aws.org }
#
# provider "aws" {
#   alias  = "org"
#   region = local.metadata.aws_region
#   assume_role { role_arn = "arn:aws:iam::<MGMT_ACCOUNT_ID>:role/TerraformOrgAdmin" }
# }

variable "name" {
  type        = string
  description = "Organization policy name."
}

variable "description" {
  type        = string
  description = "Organization policy description."
  default     = null
}

variable "type" {
  type        = string
  description = "Organization policy type (SERVICE_CONTROL_POLICY, RESOURCE_CONTROL_POLICY, DECLARATIVE_POLICY_EC2, TAG_POLICY, ...)."
  default     = "SERVICE_CONTROL_POLICY"
  nullable    = false
}

variable "content" {
  type        = string
  description = "Policy document (JSON) for the given policy type."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the organization policy."
  default     = {}
}

variable "targets" {
  type        = map(string)
  description = "Target as written => resolved root, OU or account ID to attach the policy to (null when the target could not be resolved)."
  default     = {}
}

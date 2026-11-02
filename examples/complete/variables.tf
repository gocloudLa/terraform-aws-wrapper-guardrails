/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

# variable "metadata" {
#   type = any
# }

/*----------------------------------------------------------------------*/
/* Guardrails | Variable Definition                                     */
/*----------------------------------------------------------------------*/
variable "guardrails_parameters" {
  type        = any
  description = "Guardrails parameteres to configure the wrapper module"
  default     = {}
}

variable "guardrails_defaults" {
  type        = any
  description = "Guardrails default parameteres for the wrapper module"
  default     = {}
}

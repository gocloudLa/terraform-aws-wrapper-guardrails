/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

variable "metadata" {
  type = any
}

/*----------------------------------------------------------------------*/
/* Guardrails | Variable Definition                                     */
/*----------------------------------------------------------------------*/

variable "guardrails_parameters" {
  type        = any
  description = "Organization guardrails: built-in SCP catalog, custom organization policies and their targets."
  default     = {}
}

variable "guardrails_defaults" {
  type        = any
  description = "Default values merged into each entry of guardrails_parameters."
  default     = {}
}

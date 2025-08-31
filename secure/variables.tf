variable "prefix" {
  description = "Short, unique prefix for resource names (3-8 chars)"
  type        = string
  default     = "policyascodedemo"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "insecure_admin_password" {
  description = "Demo-only VM password (intentionally weak-ish for password-auth demo)"
  type        = string
  default     = "P@ssword1234!" # change if your org has stricter complexity policies
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  default     = { project = "policy-as-code-demo", phase = "insecure" }
}

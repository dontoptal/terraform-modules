variable "project" {
  description = "Project prefix to append to resource names for uniqueness."
  type        = string
  default     = "default"
}

variable "env" {
  description = "Environment suffix to append to resource names for uniqueness."
  type        = string
  default     = "default"
}

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket for state file history."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

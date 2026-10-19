variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Globally unique name for the test bucket"
  type        = string

  default = "devops-codex-232101830589-private-module-20261017"

  validation {
    condition = (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    )

    error_message = "Use a 3-63 character bucket name with lowercase letters, numbers, dots, or hyphens, starting and ending with a letter or number."
  }
}

variable "environment" {
  description = "Environment represented by the bucket"
  type        = string
  default     = "lab"

  validation {
    condition     = contains(["dev", "test", "lab", "prod"], var.environment)
    error_message = "Environment must be dev, test, lab, or prod."
  }
}

variable "enable_versioning" {
  description = "Whether object versioning is enabled"
  type        = bool
  default     = true
}

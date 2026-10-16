
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "project_name" {
  description = "Name of the project for the generated note."
  type        = string
  default     = "git-devops-workflow"
}

variable "environment" {
  description = "Environment label for this learning exercise."
  type        = string
  default     = "dev"
}

resource "local_file" "project_note" {
  filename = "${path.module}/generated-note.txt"

  content = <<-EOT
    Managed by Terraform

    Project: ${var.project_name}
    Lab: Terraform fundamentals
    Environment: ${var.environment}
  EOT
}

output "generated_file_path" {
  description = "Path to the generated note."
  value       = local_file.project_note.filename
}

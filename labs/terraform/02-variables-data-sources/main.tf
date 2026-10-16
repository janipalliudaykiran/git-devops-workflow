
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

locals {
  note_filename = "${path.module}/${var.project_name}-${var.environment}.txt"
}

resource "local_file" "project_note" {
  filename = local.note_filename

  content = <<-EOT
    Managed by Terraform

    Project: ${var.project_name}
    Environment: ${var.environment}
  EOT
}

data "local_file" "read_back" {
  filename = local_file.project_note.filename
}


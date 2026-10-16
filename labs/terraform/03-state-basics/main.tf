terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "state_demo" {
  filename = "${path.module}/state-demo.txt"

  content = <<-EOT
    Managed by Terraform
    Resource: local_file.state_demo
    Purpose: Learn Terraform state
  EOT
}

output "managed_file_path" {
  value = local_file.state_demo.filename
}

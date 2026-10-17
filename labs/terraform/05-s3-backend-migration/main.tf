terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "tfstate-232101830589-ap-south-1-20261017"
    key          = "devops-codex/terraform/05-s3-backend-migration/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "remote_state_demo" {
  filename = "${path.module}/remote-state-demo.txt"

  content = <<-EOT
    Managed by Terraform
    State migration lab
  EOT
}

output "managed_file_path" {
  value = local_file.remote_state_demo.filename
}

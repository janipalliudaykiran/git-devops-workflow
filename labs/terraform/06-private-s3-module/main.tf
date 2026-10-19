terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "tfstate-232101830589-ap-south-1-20261017"
    key          = "devops-codex/terraform/06-private-s3-module/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "private_bucket" {
  source = "./modules/private-s3-bucket"

  bucket_name       = var.bucket_name
  environment       = var.environment
  enable_versioning = var.enable_versioning
}

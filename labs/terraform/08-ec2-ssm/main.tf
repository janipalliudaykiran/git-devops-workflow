terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "tfstate-232101830589-ap-south-1-20261017"
    key          = "devops-codex/terraform/08-ec2-ssm/terraform.tfstate"
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

# Find the VPC created in the previous lab.
data "aws_vpc" "lab" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Find the first public subnet in that VPC.
data "aws_subnet" "public_1" {
  filter {
    name   = "tag:Name"
    values = [var.public_subnet_name]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.lab.id]
  }
}

# Find the latest matching Amazon Linux 2023 x86_64 AMI.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Trust policy: allow EC2 to assume this role.
resource "aws_iam_role" "ssm" {
  name = "${var.instance_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }
}

# Permissions used by SSM Agent.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 uses an instance profile to receive the role.
resource "aws_iam_instance_profile" "ssm" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.ssm.name
}

# No inbound rules are declared.
resource "aws_security_group" "ec2" {
  name        = "${var.instance_name}-sg"
  description = "No inbound access; outbound HTTPS for Systems Manager"
  vpc_id      = data.aws_vpc.lab.id

  tags = {
    Name      = "${var.instance_name}-sg"
    ManagedBy = "Terraform"
  }
}

# Allow outbound HTTPS to AWS service endpoints.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.ec2.id

  description = "HTTPS outbound for Systems Manager"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

# Create the EC2 instance.
resource "aws_instance" "lab" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type

  subnet_id                   = data.aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ssm.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name      = var.instance_name
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }

  # Ensure the SSM policy attachment is created before EC2.
  depends_on = [aws_iam_role_policy_attachment.ssm]
}

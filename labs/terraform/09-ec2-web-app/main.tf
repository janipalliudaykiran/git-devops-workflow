terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "tfstate-232101830589-ap-south-1-20261017"
    key          = "devops-codex/terraform/09-ec2-web-app/terraform.tfstate"
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

# Find the VPC created in Lesson 7.
data "aws_vpc" "lab" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Find the existing public subnet.
data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = [var.public_subnet_name]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.lab.id]
  }
}

# Find a current Amazon Linux 2023 x86_64 AMI.
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

# Allow EC2 to assume this role.
resource "aws_iam_role" "ssm" {
  name = "${var.instance_name}-ssm-role"

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

# Grant the instance Systems Manager permissions.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 receives the role through its instance profile.
resource "aws_iam_instance_profile" "ssm" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.ssm.name
}

# Public HTTP for the demo; HTTPS egress for package installation and SSM.
resource "aws_security_group" "web" {
  name        = "${var.instance_name}-sg"
  description = "HTTP web demo with no inbound SSH"
  vpc_id      = data.aws_vpc.lab.id

  ingress {
    description = "HTTP web traffic"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS outbound"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.instance_name}-sg"
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }
}

# Create the web server and configure it on first boot.
resource "aws_instance" "web" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type

  subnet_id                   = data.aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
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

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf install -y nginx

    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>Terraform Web Lab</title>
    </head>
    <body>
      <h1>Hello from my Terraform-managed EC2 application!</h1>
      <p>Nginx was installed automatically using EC2 user data.</p>
      <p>Project: devops-codex</p>
    </body>
    </html>
    HTML

    printf 'ok\n' > /usr/share/nginx/html/health

    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = {
    Name      = var.instance_name
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm
  ]
}

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

# Identify the AWS account for the SNS topic policy.
data "aws_caller_identity" "current" {}

locals {
  cpu_alarm_name = "devops-codex-web-cpu-high"
}

# SNS topic for alarm and recovery messages.
resource "aws_sns_topic" "alerts" {
  name = "devops-codex-web-alerts-232101830589"

  tags = {
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }
}

# Allow the account owner and the specified CloudWatch alarm
# to use this topic.
data "aws_iam_policy_document" "alerts_topic" {

  policy_id = "__default_policy_ID"

  # Allow the AWS account owner to manage the SNS topic.
  statement {
    sid    = "AllowAccountOwner"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:GetDataProtectionPolicy",
      "SNS:GetTopicAttributes",
      "SNS:ListSubscriptionsByTopic",
      "SNS:ListTagsForResource",
      "SNS:Publish",
      "SNS:PutDataProtectionPolicy",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:Subscribe"
    ]

    resources = [aws_sns_topic.alerts.arn]
  }

  # Allow CloudWatch to publish alarm notifications.
  statement {
    sid    = "AllowCloudWatchAlarmPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    actions = ["SNS:Publish"]

    resources = [aws_sns_topic.alerts.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${local.cpu_alarm_name}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts_topic.json
}

# Alert when the instance's average CPU is high.
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name        = local.cpu_alarm_name
  alarm_description = "EC2 average CPU is at least 70% for 2 of 3 five-minute periods."

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"
  period      = 300

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 70

  evaluation_periods  = 3
  datapoints_to_alarm = 2

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  treat_missing_data = "missing"

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  insufficient_data_actions = []

  # Ensure the SNS permissions are in place before enabling the alarm.
  depends_on = [
    aws_sns_topic_policy.alerts
  ]
}

terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "tfstate-232101830589-ap-south-1-20261017"
    key          = "devops-codex/terraform/10-ecs-fargate/terraform.tfstate"
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

# Look up the VPC created in the previous Terraform lesson.
data "aws_vpc" "lab" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Look up the first public subnet.
data "aws_subnet" "public_1" {
  filter {
    name   = "tag:Name"
    values = [var.public_subnet_1_name]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.lab.id]
  }
}

# Look up the second public subnet.
data "aws_subnet" "public_2" {
  filter {
    name   = "tag:Name"
    values = [var.public_subnet_2_name]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.lab.id]
  }
}

# Look up the exact image tag in the existing ECR repository.
data "aws_ecr_image" "app" {
  repository_name = var.ecr_repository_name
  image_tag       = var.image_tag
}

# Create a separate ECS cluster for this Terraform lab.
resource "aws_ecs_cluster" "app" {
  name = "devops-codex-fargate-cluster"

  tags = {
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }
}

# Store container application logs.
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/devops-codex-fargate"
  retention_in_days = 7

  tags = {
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }
}

# Trust policy: allow ECS tasks to assume the execution role.
resource "aws_iam_role" "execution" {
  name = "devops-codex-fargate-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }
}

# Permit ECR image pulls and CloudWatch log delivery.
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Network security for the Fargate task.
resource "aws_security_group" "tasks" {
  name        = "devops-codex-fargate-sg"
  description = "Restricted HTTP access to the Fargate application"
  vpc_id      = data.aws_vpc.lab.id

  tags = {
    Name      = "devops-codex-fargate-sg"
    ManagedBy = "Terraform"
  }
}

# Permit application access only from your public IP.
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.tasks.id

  description = "HTTP access from learner public IP"
  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = var.allowed_client_cidr
}

# Permit HTTPS outbound for ECR and CloudWatch Logs.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.tasks.id

  description = "HTTPS outbound"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

# Define how the application container runs.
resource "aws_ecs_task_definition" "app" {
  family                   = "devops-codex-python-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "devops-python-app"
      image     = data.aws_ecr_image.app.image_uri
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD",
          "python",
          "-c",
          "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)"
        ]

        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])

  tags = {
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }
}

# Keep one copy of the application running on Fargate.
resource "aws_ecs_service" "app" {
  name            = "devops-codex-python-app-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn

  launch_type      = "FARGATE"
  platform_version = "LATEST"
  desired_count    = 1

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets = [
      data.aws_subnet.public_1.id,
      data.aws_subnet.public_2.id
    ]

    security_groups = [
      aws_security_group.tasks.id
    ]

    assign_public_ip = true
  }

  wait_for_steady_state = true

  tags = {
    ManagedBy = "Terraform"
    Project   = "devops-codex"
  }

  # Ensure permissions exist before ECS attempts to start tasks.
  depends_on = [
    aws_iam_role_policy_attachment.execution
  ]
}

provider "aws" {
  region = var.region
}

# Create a VPC with public subnets for ECS Fargate
# This example uses the terraform-aws-modules/vpc/aws module from the Terraform Registry
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ecs-vpc"
  cidr = var.vpc_cidr

  azs = ["us-east-2a", "us-east-2b"]
  public_subnets = [cidrsubnet(var.vpc_cidr, 8, 0), cidrsubnet(var.vpc_cidr, 8, 1)]

  # Prevent creation of private subnets and NAT gateways
  private_subnets = []
  enable_nat_gateway = false

  manage_default_network_acl = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# Create a security group for the ECS service
# This security group allows inbound traffic on port 5000 (HTTP) from all sources
resource "aws_security_group" "ecs" {
  name        = "ecs_security_group"
  description = "ECS security group"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name        = "ecs_security_group"
    Environment = var.environment
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from all sources (this is common for testing, but tighten for production to only allow necessary IPs)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an ECS cluster
# This cluster will be used to run the ECS Fargate tasks
resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

# Create an IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name               = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the AmazonECSTaskExecutionRolePolicy managed policy to the role
# This policy allows ECS tasks to pull images from ECR and write logs to CloudWatch
resource "aws_iam_policy_attachment" "ecs_task_execution_policy" {
  name       = "ecs_task_execution_policy"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  roles      = [aws_iam_role.ecs_task_execution.name]
}

# Define the CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/my-flask-app"
  retention_in_days = 30  # Adjust the retention period as necessary
}

# Create the ECS task definition
resource "aws_ecs_task_definition" "flask" {
  family                   = "flask-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name  = "flask-app-container"
    image = var.ecr_image_uri
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "${aws_cloudwatch_log_group.ecs_log_group.name}"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# Create the ECS service
resource "aws_ecs_service" "flask" {
  name            = "flask-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    subnets         = [aws_subnet.main.id]
    security_groups = [aws_security_group.ecs.id]
  }
}

# Create a random ID for the S3 bucket name to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 6 # 6 bytes * 2 hex chars per byte = 12 hex chars
}

# Create an S3 bucket for file uploads
resource "aws_s3_bucket" "main" {
  bucket = "my-wetransfer-clone-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "my-wetransfer-clone-bucket"
    Environment = var.environment
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create policy for the task execution role to access the S3 bucket
resource "aws_iam_role_policy" "s3_and_logs_access" {
  name   = "S3AndLogsAccessPolicy"
  role   = aws_iam_role.ecs_task_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
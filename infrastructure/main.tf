provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 0) # Determines a /24 subnet CIDR
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_security_group" "ecs" {
  name        = "ecs_security_group"
  description = "ECS security group"
  vpc_id      = aws_vpc.main.id

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

resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

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

resource "random_id" "bucket_suffix" {
  byte_length = 6 # 6 bytes * 2 hex chars per byte = 12 hex chars
}

resource "aws_s3_bucket" "main" {
  bucket = "my-wetransfer-clone-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "my-wetransfer-clone-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

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
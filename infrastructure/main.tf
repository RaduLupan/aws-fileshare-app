provider "aws" {
  region = var.region
}

# Create a VPC with public subnets for ECS Fargate
# This example uses the terraform-aws-modules/vpc/aws module from the Terraform Registry
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ecs-vpc"
  cidr = var.vpc_cidr

  azs            = ["us-east-2a", "us-east-2b"]
  public_subnets = [cidrsubnet(var.vpc_cidr, 8, 0), cidrsubnet(var.vpc_cidr, 8, 1)]

  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 2), cidrsubnet(var.vpc_cidr, 8, 3)]

  enable_nat_gateway = true
  single_nat_gateway = true # This ensures only one NAT Gateway is created

  manage_default_network_acl = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# BACKEND - Create a security group for the ECS service
# This security group allows inbound traffic on port 5000 (HTTP) from all sources
resource "aws_security_group" "backend_ecs" {
  name        = "ecs_security_group"
  description = "ECS security group"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name        = "ecs_security_group"
    Environment = var.environment
  }
}

# BACKEND - Allow inbound traffic on port 5000 (HTTP) from all sources
# This rule allows the ECS service to receive HTTP requests on port 5000
resource "aws_vpc_security_group_ingress_rule" "allow_tcp_5000" {
  security_group_id = aws_security_group.backend_ecs.id

  from_port                    = 5000
  ip_protocol                  = "tcp"
  to_port                      = 5000
  referenced_security_group_id = aws_security_group.alb.id # Allow traffic from the ALB security group
}

# BACKEND - Allow all outbound traffic from the ECS security group
# This rule allows the ECS service to communicate with other AWS services and the internet
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.backend_ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# BACKEND - Create a security group for the Application Load Balancer 
resource "aws_security_group" "alb" {
  name        = "flask_app_alb_security_group"
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name        = "alb_security_group"
    Environment = var.environment
  }
}

# BACKEND - Allow inbound traffic on port 80 (HTTP) from all sources
resource "aws_vpc_security_group_ingress_rule" "allow_tcp_80" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# BACKEND - Allow inbound traffic on port 443 (HTTPS) from all sources
resource "aws_vpc_security_group_ingress_rule" "allow_tcp_443" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# BACKEND - Allow all outbound traffic from the ECS security group
# This rule allows the ECS service to communicate with other AWS services and the internet
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_2" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# BACKEND - Create an Application Load Balancer (ALB)
# This ALB will distribute incoming traffic to the ECS service
resource "aws_lb" "flask_app_lb" {
  name               = "flask-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets # Use at least two public subnets in different AZs

  enable_deletion_protection = false # Consider setting to true for production

  tags = {
    Name        = "flask-app-lb"
    Environment = var.environment
  }
}
# BACKEND - Create a Target Group for the ALB
# This target group will route traffic to the ECS service
resource "aws_lb_target_group" "flask_app_tg" {
  name        = "flask-app-tg"
  port        = 5000 # Port your Flask container listens on
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id # Replace with your actual VPC ID reference
  target_type = "ip"              # Required for Fargate

  health_check {
    enabled             = true
    path                = "/" # Your Flask app's root path, ensure it returns 200 OK
    protocol            = "HTTP"
    port                = "traffic-port" # Checks on the same port as traffic
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200" # Expect HTTP 200 for a healthy target
  }

  tags = {
    Name        = "flask-app-tg"
    Environment = var.environment
  }
}

# BACKEND - Create a HTTP listener for the ALB
# This listener will forward HTTP traffic to the target group
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.flask_app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_app_tg.arn
  }
}

/* # Create a HTTPS listener for HTTPS traffic
# This listener will forward HTTPS traffic to the target group
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.flask_app_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-2016-08" # Choose an appropriate SSL policy

  certificate_arn = var.certificate_arn # Replace with your ACM certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_app_tg.arn
  }
}
 */

# Create an ECS cluster
# This cluster will be used to run the ECS Fargate tasks
resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

# Create an IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs_task_execution_role"
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
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution.name
}

# BACKEND - Create a new IAM role specifically for the Flask application task
resource "aws_iam_role" "flask_app_task" {
  name = "flask_app_task_role" # Choose a descriptive name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # This allows the containers in your task to assume this role
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# BACKEND - Define the policy containing only the S3 permissions needed by the application
resource "aws_iam_policy" "flask_app_s3_access" {
  name        = "FlaskS3AccessPolicy" # Choose a descriptive name
  description = "Allows Flask app task to access specific S3 bucket"

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
          # Replace aws_s3_bucket.main.arn with your actual S3 bucket resource reference if different
          aws_s3_bucket.uploads_backend.arn,
          "${aws_s3_bucket.uploads_backend.arn}/*"
        ]
      }
    ]
  })
}

# Attach the S3 access policy to the new Flask application task role
resource "aws_iam_role_policy_attachment" "flask_app_s3_policy_attachment" {
  policy_arn = aws_iam_policy.flask_app_s3_access.arn
  role       = aws_iam_role.flask_app_task.name
}

# BACKEND - Define the CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group_backend" {
  name              = "/ecs/my-flask-app"
  retention_in_days = 30 # Adjust the retention period as necessary
}

# BACKEND - Create the ECS task definition
resource "aws_ecs_task_definition" "flask" {
  family                   = "flask-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  # Role for ECS agent (pulling images, basic logs)
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  # Role for your application container (accessing S3, etc.)
  task_role_arn = aws_iam_role.flask_app_task.arn

  container_definitions = jsonencode([{
    name      = "flask-app-container"
    image     = var.ecr_image_uri_backend
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        # Ensure aws_cloudwatch_log_group.ecs_log_group is defined elsewhere in your Terraform code
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group_backend.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# BACKEND - Create the ECS service
resource "aws_ecs_service" "flask" {
  name            = "flask-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Enable ECS-managed health checks integrated with ALB health checks
  health_check_grace_period_seconds  = 60 # Time for task to start before health checks begin
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {

    # Tasks no longer need public IPs; they are fronted by the ALB
    assign_public_ip = false
    subnets          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]] # Use private subnest for better security
    security_groups  = [aws_security_group.backend_ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flask_app_tg.arn
    container_name   = "flask-app-container" # From your task definition                           
    container_port   = 5000                  # Ensure this matches the port in your task definition
  }

  # Optional: Ensure listener is created before service attempts to register
  # Terraform usually handles this via ARN dependencies, but explicit depends_on can be used if needed.
  # depends_on = [aws_lb_listener.http_listener]

  # Propagate tags to ECS-managed ENIs. Helpful for cost allocation & resource tracking.
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE" # or "TASK_DEFINITION"
}

# Create random IDs for the S3 bucket names to ensure uniqueness
resource "random_id" "bucket_suffix" {
  count = 2
  byte_length = 6 # 6 bytes * 2 hex chars per byte = 12 hex chars
}

# BACKEND - Create an S3 bucket for file uploads
resource "aws_s3_bucket" "uploads_backend" {
  bucket = "my-wetransfer-clone-file-uploads-${random_id.bucket_suffix[0].hex}"

  tags = {
    Name        = "my-wetransfer-clone-file-uploads"
    Service     = "Backend"
    Environment = var.environment
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.uploads_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# FRONTEND - Create an S3 bucket for the React frontend
# This bucket will host the static files for the React app
resource "aws_s3_bucket" "react_frontend" {
  bucket = "my-wetransfer-clone-react-frontend-${random_id.bucket_suffix[1].hex}"
  tags = {
    Environment = var.environment
    Service     = "Frontend"
  }
}

# S3 Bucket Public Access Block (Recommended for all S3 buckets)
resource "aws_s3_bucket_public_access_block" "react_frontend_public_access_block" {
  bucket = aws_s3_bucket.react_frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy to allow CloudFront OAC access
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.react_frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.react_frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      },
    ]
  })
}

# FRONTEND - Create a CloudFront Origin Access Control (OAC)
# This OAC allows CloudFront to access the S3 bucket
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "my-wetransfer-clone-react-frontend-oac"
  description                       = "OAC for S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# FRONTEND - Create a CloudFront distribution for the React app
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.react_frontend.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.react_frontend.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for my-wetransfer-clone-react-frontend"
  default_root_object = "index.html" # Your React app's entry point

  # Define default cache behavior
  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.react_frontend.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false # Don't forward query strings for static assets
      headers      = []
      cookies {
        forward = "none"
      }
    }

    # TTL settings (adjust as needed for your caching strategy)
    min_ttl                = 0
    default_ttl            = 86400 # 24 hours
    max_ttl                = 31536000 # 1 year
  }

  # For React Router to handle client-side routing when hitting a non-existent path
  # CloudFront will serve index.html for 403/404 errors with a 200 OK status.
  custom_error_response {
    error_code         = 403
    response_page_path = "/index.html"
    response_code      = 200
  }

  custom_error_response {
    error_code         = 404
    response_page_path = "/index.html"
    response_code      = 200
  }

  # Optional: Custom domain configuration
  # If you use a custom domain, you need an ACM certificate in us-east-1.
  # Otherwise, comment out or remove this block.
  # To use this, you must have an AWS Certificate Manager (ACM) certificate
  # in the us-east-1 region for your domain (e.g., yourdomain.com).
  # You'll need to create this certificate manually or with a separate Terraform module.

  # aliases = var.custom_domain_name != "" ? [var.custom_domain_name] : []

  viewer_certificate {
    # cloudfront_default_certificate = var.custom_domain_name == "" ? true : false
    # acm_certificate_arn            = var.custom_domain_name != "" ? var.acm_certificate_arn : null
    cloudfront_default_certificate = true
    ssl_support_method             = "sni-only" # Or "vip" for older clients if needed
    minimum_protocol_version       = "TLSv1.2_2021"
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none" # Or "whitelist", "blacklist"
      locations        = []
    }
  }

  tags = {
    Environment = var.environment
    Service     = "Frontend"
  }
}

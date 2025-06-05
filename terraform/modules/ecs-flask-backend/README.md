# Terraform Module: ECS Fargate Flask Backend

This Terraform module provisions the AWS infrastructure required to deploy a containerized Flask application to Amazon ECS using Fargate launch type, fronted by an Application Load Balancer (ALB). It also includes the necessary IAM roles, ECR repository, and an S3 bucket for file uploads.

## Features

* Creates an Amazon ECS Cluster.
* Provisions an Amazon ECR Repository for your Docker image.
* Defines ECS Task Execution and Task Roles with necessary permissions (e.g., S3 access).
* Sets up an ECS Task Definition for the Flask application.
* Deploys an ECS Service to run the Flask tasks on Fargate.
* Configures an Application Load Balancer (ALB) with HTTP and optional HTTPS listeners to route traffic to ECS tasks.
* Includes a dedicated S3 bucket for handling file uploads from the Flask application.
* Sets up CloudWatch Log Group for application logs.

## Usage

```terraform
module "backend_app" {
  source = "../../modules/ecs-flask-backend" # Adjust path as necessary

  project_name                  = "my-file-sharing-app"
  environment                   = "dev"
  aws_region                    = "us-east-2" # Must match region where VPC and subnets are
  vpc_id                        = module.network.vpc_id
  public_subnet_ids             = module.network.public_subnet_ids
  private_subnet_ids            = module.network.private_subnet_ids
  alb_security_group_id         = module.network.alb_security_group_id
  ecs_tasks_security_group_id   = module.network.ecs_tasks_security_group_id

  # Note: The ECR image URI is now dynamically generated within the module.
  # You will push your Docker image to the repository provided in `ecr_repository_url` output.
  container_port                = 5000
  cpu                           = 256
  memory                        = 512
  desired_count                 = 1 # Set to 0 for initial deployment, then update after image push

  enable_alb_deletion_protection = false # Set to true for production
  alb_health_check_path         = "/"
  alb_listener_http_port        = 80

  # Optional: Enable HTTPS listener
  enable_https_listener         = false
  alb_listener_https_port       = 443
  # alb_https_certificate_arn   = "arn:aws:acm:us-east-2:123456789012:certificate/your-cert-id" # Required if enable_https_listener is true

  s3_uploads_bucket_name_prefix = "my-file-sharing-uploads"
  log_retention_in_days         = 30
}
```

## Inputs
| Name | Description | Type | Default | Required|
|---|---|---|---|---|
|`project_name`| The name of your project, used as a prefix for resources.| `string`| | yes|
|`environment`| The environment name (e.g., dev, staging, prod).| `string`| | yes|
|`aws_region`| The AWS region to deploy resources in.| `string`| | yes|
|`vpc_id`| The ID of the VPC where the ECS service will run.| `string`| | yes|
|`public_subnet_ids`| A list of public subnet IDs for the ALB.| `list(string)`| | yes|
|`private_subnet_ids`| A list of private subnet IDs for the ECS tasks.| `list(string)	`| | yes|
|`alb_security_group_id`| The ID of the security group for the ALB.| `string`| | yes|
|`ecs_tasks_security_group_id`| The ID of the security group for ECS tasks.| `string`| | yes|
|`container_port`| The port on which the Flask container listens.| `number`| 5000| no|
|`cpu`| The amount of CPU to reserve for the task (in CPU units).| `number`| 256| no|
|`memory`| The amount of memory to reserve for the task (in MiB).| `number`| 512| no|
|`desired_count`| The desired number of running tasks for the ECS service.| `number`| 0| no|
|`enable_alb_deletion_protection`| Whether deletion protection is enabled for the ALB.| `bool`| `false`| no|
|`alb_health_check_path`| 


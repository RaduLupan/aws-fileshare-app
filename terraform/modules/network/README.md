# Terraform Module: AWS Network (VPC, Subnets, Security Groups)

This Terraform module provisions a dedicated Virtual Private Cloud (VPC) in AWS, including public and private subnets, NAT Gateways (for private subnet internet access), and core security groups for common application components like Application Load Balancers (ALBs) and ECS Fargate tasks.

## Features

* Creates a new VPC with a specified CIDR block.
* Provisions public and private subnets across multiple Availability Zones.
* Includes an Internet Gateway for public subnets and optional NAT Gateway(s) for private subnets.
* Manages default network ACLs.
* Defines a security group for Application Load Balancers (ALBs), allowing HTTP/HTTPS ingress from the internet.
* Defines a security group for ECS Fargate tasks, allowing ingress only from the ALB security group and all outbound traffic.

## Usage

```terraform
module "network" {
  source = "../../modules/network" # Adjust path as necessary

  project_name       = "my-file-sharing-app"
  environment        = "dev"
  aws_region         = "us-east-2" # Match your desired region
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-2a", "us-east-2b"] # Match your desired region's AZs
  # public_subnet_cidrs and private_subnet_cidrs can be left empty to use defaults
  enable_nat_gateway = true
  single_nat_gateway = true
  ecs_service_port   = 5000 # The port your ECS tasks listen on
  alb_http_port      = 80
  alb_https_port     = 443
}
```

## Inputs
| Name | Description | Type | Default | Required|
|---|---|---|
|`project_name`| The name of your project, used as a prefix for resources.| `string`| "my-file-sharing-app"| no|
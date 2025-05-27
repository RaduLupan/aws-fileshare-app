# outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = module.vpc.public_subnets[0]
}

output "security_group_id" {
  description = "The ID of the security group for ECS"
  value       = aws_security_group.backend_ecs.id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_task_definition_arn" {
  description = "The ARN of the ECS task definition"
  value       = aws_ecs_task_definition.flask.arn
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.flask.name
}

output "backend_s3_bucket_name" {
  description = "The name of the S3 bucket for file uploads"
  value       = aws_s3_bucket.uploads_backend.bucket
}

output "frontend_s3_bucket_name" {
  description = "The name of the S3 bucket for the React app"
  value       = aws_s3_bucket.react_frontend.bucket
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution for the React app."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

# outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = aws_subnet.main.id
}

output "security_group_id" {
  description = "The ID of the security group for ECS"
  value       = aws_security_group.ecs.id
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

output "availability_zone" {
  description = "The availability zone used by the subnet"
  value       = aws_subnet.main.availability_zone
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket
}
# terraform/environments/dev/main.tf

provider "aws" {
  region = var.aws_region
}

# Define your remote backend here
# terraform {
#   backend "s3" {
#     bucket         = "your-dev-terraform-state-bucket" # Create this bucket manually once
#     key            = "frontend/state"
#     region         = "us-east-1"
#     dynamodb_table = "your-dev-terraform-state-lock" # Create this DynamoDB table manually once
#     encrypt        = true
#   }
# }

# Call the frontend module
module "frontend_app" {
  source = "../../modules/s3-cloudfront-frontend" # Path to your module

  # Pass variables to the module
  environment          = var.environment
  bucket_name_prefix   = "my-file-share-dev" # Unique prefix for this environment
  cloudfront_comment   = "Dev CloudFront distribution for My File Share"
  viewer_protocol_policy = "allow-all" # For dev testing, change to "redirect-to-https" for production env

  # If you decide to use a custom domain later for dev:
  # custom_domain_name   = "dev.example.com"
  # acm_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
}

# Output relevant values from the module
output "frontend_url" {
  description = "The URL of the deployed frontend application."
  value       = "http://${module.frontend_app.cloudfront_domain_name}" # Use http for now due to "allow-all"
}

output "s3_bucket_name" {
  description = "The S3 bucket name for the frontend."
  value       = module.frontend_app.s3_bucket_name
}
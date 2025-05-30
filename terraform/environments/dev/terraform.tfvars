aws_region  = "us-east-1" # CloudFront requires S3 origin in us-east-1 if using default cert
environment = "dev"
ecr_image_uri_flask = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-flask-app:latest" # Replace with your actual ECR image URI
project_name = "my-file-sharing-app"
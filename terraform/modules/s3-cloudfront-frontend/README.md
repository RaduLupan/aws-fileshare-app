# Terraform Module: S3 + CloudFront Frontend

This Terraform module provisions the necessary AWS infrastructure to host a static frontend application (e.g., a React, Angular, or Vue.js build) using an S3 bucket as the origin and CloudFront as the Content Delivery Network (CDN).

## Features

* Creates a private Amazon S3 bucket for storing static assets.
* Configures an S3 Bucket Policy to allow access only from CloudFront.
* Sets up a CloudFront Origin Access Control (OAC) for secure S3 integration (recommended over OAI).
* Deploys an Amazon CloudFront distribution for global content delivery and caching.
* Configures CloudFront for Single-Page Application (SPA) routing (e.g., `/index.html` for 403/404 errors).
* Supports both HTTP and HTTPS access (via CloudFront's default certificate or optional custom domain).
* Optionally configures a custom domain with an ACM certificate.
* Optionally configures a second origin and behavior for proxying API calls through CloudFront (e.g., `/api/*` to an ALB).

## Usage

```terraform
module "frontend_app" {
  source = "../../modules/s3-cloudfront-frontend" # Adjust path as necessary

  environment            = var.environment
  bucket_name_prefix     = "${var.project_name}-${var.environment}-frontend"
  cloudfront_comment     = "${var.environment} CloudFront distribution for ${var.project_name} frontend"
  viewer_protocol_policy = "allow-all" # Options: "allow-all", "redirect-to-https", "https-only"

  # Optional: For custom domain (requires ACM cert in us-east-1)
  # custom_domain_name     = "app.yourdomain.com"
  # acm_certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"

  # Optional: For proxying API calls through CloudFront (requires ALB DNS name)
  # backend_alb_dns_name = module.backend_app.alb_dns_name
  # alb_http_port        = module.network.alb_http_port
  # alb_https_port       = module.network.alb_https_port
}
```
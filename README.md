# FileShare - A Simple File Sharing Application

## Overview

FileShare is a minimalist web application designed to allow users to easily upload files and share them via a unique download link. This project serves as a proof-of-concept (MVP) demonstrating a full-stack deployment on AWS using React for the frontend, Flask for the backend, and Terraform for infrastructure as code.

### Key Features (MVP)

* **File Uploads:** Users can select a file from their local machine and upload it.
* **Unique Download Links:** Upon successful upload, a unique, time-limited download URL is generated for sharing.
* **Cloud-Native Architecture:** Deployed entirely on AWS, leveraging managed services for scalability and reliability.

## Architecture

The application is composed of three main components:

1.  **Frontend (React App):** A static single-page application (SPA) providing the user interface for file uploads.
2.  **Backend (Flask API):** A Python Flask application handling file uploads to S3, generating presigned download URLs, and acting as the API layer.
3.  **Infrastructure (Terraform):** All AWS resources are provisioned and managed using Terraform.

+----------------+      +-------------------+      +-----------------+      +-------------------+
|                |      |                   |      |                 |      |                   |
|  User Browser  +------> CloudFront (CDN)  +------> S3 (Frontend)   |      |                   |
|  (React App)   |      | (HTTP Access)     |      | (Static Hosting)|      |                   |
+----------------+      +-------------------+      +-----------------+      |                   |
^                         |                                        |                   |
|  API Calls (HTTP)       |                                        |                   |
+-------------------------+                                        |                   |
|                                        |                   |
|                 +----------------+     |                   |
+-----------------> ALB (Load Balancer)+---> ECS Fargate       |
| (HTTP Listener) | (Backend API)  |     | (Flask App)       |
|                 +----------------+     |                   |
|                                        |                   |
|                 +----------------+     |                   |
+-----------------> S3 (Uploads)         | (File Storage)    |
| (Backend Module) |     |                   |
+----------------+     +-------------------+
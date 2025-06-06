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

## Architecture Flow Diagram

```
+----------------+    +-------------------+    +-----------------+
|                |    |                   |    |                 |
| User Browser   +--> | CloudFront (CDN)  +--> | S3 (Frontend)   |
| (HTTP Access)  |    |                   |    | (Static Hosting)|
|                |    |                   |    | (React App)     |
+----------------+    +-------------------+    +-----------------+
                                                        |         
                                                        |         
                                                        | API Calls (HTTP)
                                                        | (via Submit button)
                                                        |         
                                                        v         
                                               +----------------+    +-------------------+
                                               |                |    |                   |
                                               | ALB (Load      +--> | ECS Fargate       |
                                               | Balancer)      |    | (Backend API)     |
                                               | (HTTP Listener)|    | (Flask App)       |
                                               |                |    |                   |
                                               +----------------+    +-------------------+
                                                        |                        |         
                                                        |                        |         
                                                        |            +-----------+         
                                                        |            |                     
                                                        |            v                     
                                                        |    +----------------+            
                                                        |    |                |            
                                                        +--> | S3 (Uploads)   |            
                                                             | (File Storage) |            
                                                             | (Backend       |            
                                                             | Module)        |            
                                                             |                |            
                                                             +----------------+            
```

## Traffic Flow Description

1. **User Browser** makes HTTP requests to **CloudFront (CDN)**.
2. **CloudFront (CDN)** serves the React application from **S3 (Frontend)** static hosting.
3. **React App** (running in user's browser) makes API calls directly to **ALB (Load Balancer)** when users interact with forms.
4. **ALB (Load Balancer)** receives API calls and distributes them to **ECS Fargate** containers.
5. **ECS Fargate (Backend API)** processes requests and interacts with **S3 (Uploads)** for file storage operations.
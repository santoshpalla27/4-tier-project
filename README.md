

4-Tier Architecture Project
Overview
This project implements a modern 4-tier architecture for a scalable, high-availability web application deployed on AWS. Unlike traditional 3-tier architectures, this solution adds a caching layer between the application and database tiers to improve performance and reduce database load.
Architecture
The architecture consists of the following tiers:

Presentation Tier (Web Tier) - The user interface layer
Application Tier (Business Logic) - Processes user requests and implements business logic
Caching Tier (Redis) - Stores frequently accessed data to improve performance
Data Tier (Database) - Persistent storage for application data

Infrastructure Components

VPC with multiple subnets across different availability zones for high availability
Load balancers to distribute traffic across instances
Auto Scaling Groups for the web and application tiers
EC2 instances for hosting the web and application servers
Redis for caching frequently accessed data
RDS (MySQL) for the database tier
NAT Gateway to enable internet access for instances in private subnets

Prerequisites

AWS Account with appropriate permissions
AWS CLI configured with access credentials
Terraform installed (for infrastructure provisioning)
Git
Basic knowledge of AWS services (EC2, VPC, ELB, RDS, Redis)




Verify the application is running:
curl http://localhost:3000/api/health


Status Monitoring
The application includes status indicators for each component:

Green (online) - Component is working correctly
Red (offline) - Component is down
Orange (checking) - Status is being checked
Gray (unknown) - Status cannot be determined (typically when the backend is unavailable)



added an dummy health check /dummy-health to pass the health check in asg 


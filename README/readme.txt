0. Pipeline overview:

    - GitHub repo contains backend code (Python), Dockerfile, frontend code (static HTML, CSS, JS) and GitHub Actions YAML workflows.
    - GitHub Actions pipelines run on every push to either frontend or backend folder (separate) on the develop branch.
    - frontend pipeline pushes static files to an AWS S3 bucket and invalidates the CloudFront cache.
    - backend pipeline builds a Docker image (as specifed in the Dockerfile) which will run the Python app.
    - Docker image is then pushed into AWS ECR and used to run the ECS tasks
    - GitHub Actions auth to AWS:
        - workflow uses OIDC Provider (GitHub) to prove its identity.
        - workflow uses the token to call STS and obtain temp credentials and assume an IAM Role.
        - IAM Role can only be assumed by Federated OIDC users and from specific GitHub repo/branch.
        - IAM Role has Permission Policy assigned that allows actions within AWS.


1. Created and configured demo environment on AWS using Terraform:

    - Network (VPC, subnets, IGW, Route Tables, VPC Endoints, Application Load Balancer / Listener / Target Group) setup.

    - Frontend resources:
    - S3 bucket for static frontend files.
    - Cloudfront distribution with the S3 bucket as its origin.
    - Backend resources:
        - ECS cluster, ECS service and ECS task which will use a Docker image from ECR, RDS database.

    - created and assigned appropriate Security Groups for resources: 
    - opening ports for inbound requests to the Application Load Balancer (API calls) and outbound traffic (for directing traffic and Health Checks).
    - opening ports for inbound and outbound traffic - to ECS containers (tasks) from ALB and from ECS containers (tasks) to ECR and for healthchecks.
    - opening ports for inbound traffic to VPC endopoints (ECS to ECR communication).
    - opening ports for inbound and outbound traffic for RDS database instances to communicate with the ECS containers.

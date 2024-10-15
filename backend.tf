#### ECS Cluster #####################################
resource "aws_ecs_cluster" "this" {
  name = "very-simple-webapp-cloud--cluster"
}



#### ECS Task ########################################
resource "aws_ecs_task_definition" "this" {
  family                   = "python_API" # name of the task (container)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn # specified below, allows pulling an image from ECR and sending logs to CloudWatch

  container_definitions = jsonencode([
    {
      name      = "backend-container"
      image     = "${var.ecr_repo_url}:${var.image_tag}" # docker image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
    }
  ])
}




#### ECS Service #####################################
resource "aws_ecs_service" "this" {
  name            = "very-simple-webapp-cloud--service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"

  scheduling_strategy                = "REPLICA"
  desired_count                      = 1   # number of containers
  deployment_minimum_healthy_percent = 100 # min instance
  deployment_maximum_percent         = 200 # max overprovisioning

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "backend-container"
    container_port   = 5000
  }

  network_configuration {
    assign_public_ip = false
    subnets          = [aws_subnet.priv-subnet-a.id, aws_subnet.priv-subnet-b.id]
    security_groups  = [aws_security_group.container-sg.id]
  }
}





#### IAM Role for ECS Task Execution #################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#### Attach Policy for ECR Access to ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

#### Attach Policy for CloudWatch Logs Access to ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#### Attach Policy for S3 Access to ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_s3" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
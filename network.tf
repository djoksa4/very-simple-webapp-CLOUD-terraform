#### VPC #############################################
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/24" # 10.0.0.1 to 10.0.0.254
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name = "very-simple-webapp-cloud--vpc"
  }
}



#### Subnets #########################################
#### PUB subnet A
resource "aws_subnet" "pub-subnet-a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.0.64/27" # 10.0.0.65 to 10.0.0.94
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnet-a"
  }
}

#### PUB subnet B
resource "aws_subnet" "pub-subnet-b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.0.32/27" # 10.0.0.33 to 10.0.0.62
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnet-b"
  }
}

#### PRIV subnet A
resource "aws_subnet" "priv-subnet-a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.0.96/27" # 10.0.0.97 to 10.0.0.126
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "priv-subnet-a"
  }
}

#### PRIV subnet B
resource "aws_subnet" "priv-subnet-b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.0.128/27" # 10.0.0.129 to 10.0.0.158
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "priv-subnet-b"
  }
}




#### Internet Gateway ################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "very-simple-webapp-cloud--igw"
  }
}




#### Public Route Table setup ########################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "very-simple-webapp-cloud--rt-pub"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}
#### Associate PUBLIC subnets with route table
resource "aws_route_table_association" "pub-sub-assoc-1" {
  subnet_id      = aws_subnet.pub-subnet-a.id # pub-subnet-a
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "pub-sub-assoc-2" {
  subnet_id      = aws_subnet.pub-subnet-b.id # pub-subnet-b
  route_table_id = aws_route_table.public.id
}



#### VPC endpoints for ECR
#### ECR DKR endpoint
resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.endpoint-sg.id]
  subnet_ids         = [aws_subnet.priv-subnet-a.id, aws_subnet.priv-subnet-b.id] # private subnets
}
#### ECR API endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.endpoint-sg.id]
  subnet_ids         = [aws_subnet.priv-subnet-a.id, aws_subnet.priv-subnet-b.id]
}
#### CloudWatch endpoint
resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.endpoint-sg.id]
  subnet_ids         = [aws_subnet.priv-subnet-a.id, aws_subnet.priv-subnet-b.id]
}
#### S3 endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}





#### Private Route Table #############################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "very-simple-webapp-cloud--rt-priv"
  }
}

#### Associate PRIVATE subnets with route table
resource "aws_route_table_association" "priv_sub_assoc-1" {
  subnet_id      = aws_subnet.priv-subnet-a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "priv_sub_assoc-2" {
  subnet_id      = aws_subnet.priv-subnet-b.id
  route_table_id = aws_route_table.private.id
}




#### ALB #############################################
resource "aws_lb" "this" {
  name               = "very-simple-webapp-cloud--alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.pub-subnet-a.id, aws_subnet.pub-subnet-b.id] # associate with public subnets

  access_logs {
    bucket  = aws_s3_bucket.troubleshooting_logs.bucket
    enabled = true
  }

  connection_logs {
    bucket  = aws_s3_bucket.troubleshooting_logs.bucket
    enabled = true
  }
}


#### Listener ########################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn # associate listener with ALB
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn # associate listener with TG
  }
}

#### Target Group ####################################
resource "aws_lb_target_group" "this" {
  name        = "very-simple-webapp-cloud--tg"
  port        = 5000 # port on which targets RECEIVE traffic
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}



#### Security Groups ##################################
#### ALB SG (from public)
resource "aws_security_group" "alb-sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#### Container SG (outbound 443)
resource "aws_security_group" "container-sg" {
  name   = "container-sg"
  vpc_id = aws_vpc.this.id

  # Ingress rules will be defined separately below (alb_to_ecs)

  # Egress rule for container tasks to access the internet or other services (if needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#### Container SG rule (all ports from ALB)
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.container-sg.id
  source_security_group_id = aws_security_group.alb-sg.id
}

#### VPC endpoint security group
resource "aws_security_group" "endpoint-sg" {
  name   = "endpoint-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#### DB SG (from ECS task)
resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.container-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

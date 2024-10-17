variable "ecr_repo_url" {
  description = "The URL of the existing ECR repository"
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image"
  type        = string
}

variable "subnet_config" {
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
  default = {
    "pub-subnet-a" = {
      cidr_block              = "10.0.0.64/27"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
    },
    "pub-subnet-b" = {
      cidr_block              = "10.0.0.32/27"
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = true
    },
    "priv-subnet-a" = {
      cidr_block              = "10.0.0.96/27"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = false
    },
    "priv-subnet-b" = {
      cidr_block              = "10.0.0.128/27"
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = false
    }
  }
}
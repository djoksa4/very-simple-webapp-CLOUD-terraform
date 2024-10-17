variable "ecr_repo_url" {
  description = "The URL of the existing ECR repository"
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image"
  type        = string
}

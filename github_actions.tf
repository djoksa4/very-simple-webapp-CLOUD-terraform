
#### OIDC Provider (GitHub) that can call STS ###################################################
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["d89e3bd43d5d909b47a18977aa9d5ce36cee184c"]
}


#### IAM Role that federated GitHub user will assume
resource "aws_iam_role" "github_oidc_role" {
  name               = "github_oidc_role"

  # Inline assume role policy
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:djoksa4/very-simple-webapp-CLOUD:ref:refs/heads/develop"
          }
        }
      }
    ]
  })
}


#### Attach Permissions to the Role
resource "aws_iam_role_policy_attachment" "github_oidc_full_access" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Managed Policy ARN
}
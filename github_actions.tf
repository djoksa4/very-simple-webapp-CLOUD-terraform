
#### OIDC Provider (GitHub) that can call STS
resource "aws_iam_openid_connect_provider" "github" {
  url                   = "https://token.actions.githubusercontent.com"
  client_id_list        = ["sts.amazonaws.com"]
  thumbprint_list       = ["D89E3BD43D5D909B47A18977AA9D5CE36CEE184C"]
}

#### Policy Template
data "aws_iam_policy_document" "oidc" {
  statement {
    # STS action that allows service (like GitHub Actions) to assume  IAM role using an OIDC token
    actions = ["sts:AssumeRoleWithWebIdentity"] 

    # Specify that  role can be assumed by GitHub’s OIDC provider
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Ensure token can only be used with  STS
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    # Check which GitHub repository is making the request
    condition {
      test     = "StringLike"
      values   = ["repo:${var.github_repo}"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

#### IAM Role
resource "aws_iam_role" "github_oidc_role" {
  name               = "github_oidc_role"
  assume_role_policy = data.aws_iam_policy_document.oidc.json
}

#### Attach Permissions to the Role
resource "aws_iam_role_policy_attachment" "github_oidc_full_access" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"  # Managed Policy ARN
}
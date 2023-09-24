output "codebuild_role_arn" {
  value       = aws_iam_role.codebuild_role.arn
  description = "Codebuild project IAM role ARN"
}
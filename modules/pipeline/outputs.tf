output "codebuild_role_arn" {
  value       = aws_iam_role.codebuild_role.arn
  description = "Codebuild project IAM role ARN"
}

output "codebuild_security_group" {
  value       = aws_security_group.codebuild_security_group.id
  description = "Codebuild project security group"
}
variable region {
  type        = string
  description = "The region of the cluster"
}

variable name {
  type        = string
  description = "The name of the stack"
}

variable app_repository_arn {
  type        = string
  description = "The ARN of the APP CodeCommit Repo"
}

variable app_repository_name {
  type        = string
  description = "The name of the APP CodeCommit Repo"
}

variable config_repository_name {
  type        = string
  description = "The name of the Codebuild config CodeCommit Repo"
}

variable prod_image_repo_name {
  type        = string
  description = "The name of ECR Repo for prod docker image"
}

variable scratch_image_repo_name {
  type        = string
  description = "The name of ECR Repo for scratch docker image"
}

variable app_repo_clone_url {
  type        = string
  description = "The clone HTTP URL of APP repo"
}

variable vulnerability_intolerance {
  type        = string
  description = "The clone HTTP URL of APP repo"
  default     = "HIGH"
  # Accepted value are
  # - LOW
  # - MEDIUM
  # - HIGH
  # - CRITICAL
}

variable tags {
  description = "Tags to be attached to the cluster"
  type        = map(any)
}
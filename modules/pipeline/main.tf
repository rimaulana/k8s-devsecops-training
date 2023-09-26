data "aws_caller_identity" "current" {}

resource "aws_ssm_parameter" "sonar_token" {
  name  = "${var.name}-sonar-token"
  type  = "SecureString"
  value = "sonar-initial-token"
}

resource "aws_ssm_parameter" "sonar_url" {
  name  = "${var.name}-sonar-url"
  type  = "SecureString"
  value = "sonar-initial-url"
}

resource "aws_ssm_parameter" "zap_token" {
  name  = "${var.name}-zap-token"
  type  = "SecureString"
  value = "zap-initial-token"
}

resource "aws_ssm_parameter" "zap_url" {
  name  = "${var.name}-zap-url"
  type  = "SecureString"
  value = "zap-initial-url"
}

# CBKSEventRule
resource "aws_cloudwatch_event_rule" "cbks_event_rule" {
  name = "${var.name}-kubesec-scan"
  description = "Triggers when builds fail/pass in CodeBuild for kubesec scan."
  event_pattern = jsonencode({
    source = [
      "aws.codebuild"
    ]
    detail-type = [
      "CodeBuild Build State Change"
    ]
    detail = {
      build-status = [
        "FAILED",
        "SUCCEEDED"
      ]
      project-name = [
        aws_codebuild_project.codebuild_kubesec_project.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cbks_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.cbks_event_rule.name
  target_id = "${var.name}-kubesec-scan"
  arn       = aws_lambda_function.lambda_cbks.arn
}

# CBSOEventRule
resource "aws_cloudwatch_event_rule" "cbso_event_rule" {
  name = "${var.name}-sonar-scan"
  description = "Triggers when builds fail/pass in CodeBuild for SonarQube scan."
  event_pattern = jsonencode({
    source = [
      "aws.codebuild"
    ]
    detail-type = [
      "CodeBuild Build State Change"
    ]
    detail = {
      build-status = [
        "FAILED",
        "SUCCEEDED"
      ]
      project-name = [
        aws_codebuild_project.codebuild_sonar_project.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cbso_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.cbso_event_rule.name
  target_id = "${var.name}-sonar-scan"
  arn       = aws_lambda_function.lambda_cbso.arn
}

# CBZPEventRule
resource "aws_cloudwatch_event_rule" "cbzp_event_rule" {
  name = "${var.name}-zap-scan"
  description = "Triggers when builds fail/pass in CodeBuild for ZAP scan."
  event_pattern = jsonencode({
    source = [
      "aws.codebuild"
    ]
    detail-type = [
      "CodeBuild Build State Change"
    ]
    detail = {
      build-status = [
        "FAILED",
        "SUCCEEDED"
      ]
      project-name = [
        aws_codebuild_project.codebuild_zap_project.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cbzp_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.cbzp_event_rule.name
  target_id = "${var.name}-zap-scan"
  arn       = aws_lambda_function.lambda_cbzp.arn
}

# CBHMEventRule
resource "aws_cloudwatch_event_rule" "cbhm_event_rule" {
  name = "${var.name}-helm-deploy"
  description = "Triggers when builds fail/pass in CodeBuild for Helm deployment."
  event_pattern = jsonencode({
    source = [
      "aws.codebuild"
    ]
    detail-type = [
      "CodeBuild Build State Change"
    ]
    detail = {
      build-status = [
        "FAILED",
        "SUCCEEDED"
      ]
      project-name = [
        aws_codebuild_project.codebuild_helm_project.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cbhm_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.cbhm_event_rule.name
  target_id = "${var.name}-helm-deploy"
  arn       = aws_lambda_function.lambda_cbhm.arn
}

# CBDFEventRule	container-devsecops-wksp-codebuild-dockerfile 	AWS::Events::Rule	CREATE_COMPLETE	-
resource "aws_cloudwatch_event_rule" "cbdf_event_rule" {
  name = "${var.name}-codebuild-dockerfile"
  description = "Triggers when builds fail/pass in CodeBuild for the static analysis of the Dockerfile."
  event_pattern = jsonencode({
    source = [
      "aws.codebuild"
    ]
    detail-type = [
      "CodeBuild Build State Change"
    ]
    detail = {
      build-status = [
        "FAILED",
        "SUCCEEDED"
      ]
      project-name = [
        aws_codebuild_project.codebuild_df_project.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cbdf_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.cbdf_event_rule.name
  target_id = "${var.name}-codebuild-dockerfile"
  arn       = aws_lambda_function.lambda_cbdf.arn
}

# CBPUEventRule	container-devsecops-wksp-codebuild-publish 	AWS::Events::Rule	CREATE_COMPLETE	-
resource "aws_cloudwatch_event_rule" "cbpu_event_rule" {
  name = "${var.name}-codebuild-publish"
  description = "Triggers when builds fail/pass in CodeBuild for the Build and Push Stage."
  event_pattern = jsonencode({
    source = [
      "aws.codebuild"
    ]
    detail-type = [
      "CodeBuild Build State Change"
    ]
    detail = {
      build-status = [
        "FAILED",
        "SUCCEEDED"
      ]
      project-name = [
        aws_codebuild_project.codebuild_publish_project.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cbpu_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.cbpu_event_rule.name
  target_id = "${var.name}-codebuild-publish"
  arn       = aws_lambda_function.lambda_cbpu.arn
}

# CBSCEventRule	container-devsecops-wksp-codebuild-secrets 	AWS::Events::Rule	CREATE_COMPLETE	-
resource "aws_cloudwatch_event_rule" "cbsc_event_rule" {
  name = "${var.name}-codebuild-secrets"
  description = "Triggers when builds fail/pass in CodeBuild for the secrets analysis."
  event_pattern = jsonencode({
    source = [
      "aws.codebuild"
    ]
    detail-type = [
      "CodeBuild Build State Change"
    ]
    detail = {
      build-status = [
        "FAILED",
        "SUCCEEDED"
      ]
      project-name = [
        aws_codebuild_project.codebuild_secrets_project.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cbsc_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.cbsc_event_rule.name
  target_id = "${var.name}-codebuild-secrets"
  arn       = aws_lambda_function.lambda_cbsc.arn
}

# CBVCEventRule	container-devsecops-wksp-codebuild-vulnerability 	AWS::Events::Rule	CREATE_COMPLETE	-
resource "aws_cloudwatch_event_rule" "cbvc_event_rule" {
  name = "${var.name}-codebuild-vulnerability"
  description = "Triggers when builds fail/pass in CodeBuild for the vulnerability scanning."
  event_pattern = jsonencode({
    source = [
      "aws.codebuild"
    ]
    detail-type = [
      "CodeBuild Build State Change"
    ]
    detail = {
      build-status = [
        "FAILED",
        "SUCCEEDED"
      ]
      project-name = [
        aws_codebuild_project.codebuild_vuln_project.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cbvc_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.cbvc_event_rule.name
  target_id = "${var.name}-codebuild-vulnerability"
  arn       = aws_lambda_function.lambda_cbvc.arn
}

# CodeBuildRole	container-devsecops-wksp-codebuild-service 	AWS::IAM::Role	CREATE_COMPLETE	-
resource "aws_iam_role" "codebuild_role" {
  name = "${var.name}-codebuild-service"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "codebuild.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  path = "/"
  
  inline_policy {
    name = "VPCConfig"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterfacePermission"
          ]
          Resource = "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:network-interface/*"
          Condition = {
            StringEquals = {
              "ec2:AuthorizedService" = "codebuild.amazonaws.com"
            }
          }
        }
      ]
    })
  }
  
  inline_policy {
    name = "LambdaInvoke"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "lambda:InvokeFunction"
          ]
          Resource = aws_lambda_function.lambda_security_hub_import.arn
        }
      ]
    })
  }
  
  inline_policy {
    name = "ServicePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "codecommit:*",
            "ssm:DescribeParameters",
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:PutParameter"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListObject"
          ]
          Resource = [
            aws_s3_bucket.pipeline_bucket.arn,
            "${aws_s3_bucket.pipeline_bucket.arn}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "ecr:*"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "eks:DescribeCluster"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:GenerateDataKey"
          ]
          Resource = "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
        }
      ]
    })
  }
}

# CodeBuildKubesecProject	
resource "aws_codebuild_project" "codebuild_kubesec_project" {
  name          = "${var.name}-kubesec-scan"
  service_role  = aws_iam_role.codebuild_role.arn
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_kubesec.yml"
  }
}

# CodeBuildSonarProject	
resource "aws_codebuild_project" "codebuild_sonar_project" {
  name          = "${var.name}-sonar-scan"
  service_role  = aws_iam_role.codebuild_role.arn
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    
    environment_variable {
      name = "SONAR_TOKEN"
      type = "PARAMETER_STORE"
      value = aws_ssm_parameter.sonar_token.name
    }
  
    environment_variable {
      name = "SONAR_URL"
      type = "PARAMETER_STORE"
      value = aws_ssm_parameter.sonar_url.name
    }
    
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_sonar.yml"
  }
  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.codebuild_subnet_ids
    security_group_ids = [aws_security_group.codebuild_security_group.id]
  }
}

# CodeBuildZAPProject	
resource "aws_codebuild_project" "codebuild_zap_project" {
  name          = "${var.name}-zap-scan"
  service_role  = aws_iam_role.codebuild_role.arn
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    
    environment_variable {
      name  = "K8S_CLUSTER_NAME"
      type  = "PLAINTEXT"
      value = var.name
    }
    
    environment_variable {
      name = "ZAP_TOKEN"
      type = "PARAMETER_STORE"
      value = aws_ssm_parameter.zap_token.name
    }
  
    environment_variable {
      name = "ZAP_URL"
      type = "PARAMETER_STORE"
      value = aws_ssm_parameter.zap_url.name
    }
    
    environment_variable {
      name = "LAMBDA_SECHUB_NAME"
      type = "PLAINTEXT"
      value = aws_lambda_function.lambda_security_hub_import.function_name
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_zap.yml"
  }
  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.codebuild_subnet_ids
    security_group_ids = [aws_security_group.codebuild_security_group.id]
  }
}

# CodeBuildHelmProject	
resource "aws_codebuild_project" "codebuild_helm_project" {
  name          = "${var.name}-deploy-helm"
  service_role  = aws_iam_role.codebuild_role.arn
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    
    environment_variable {
      name  = "K8S_CLUSTER_NAME"
      type  = "PLAINTEXT"
      value = var.name
    }
    
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      type  = "PLAINTEXT"
      value = var.scratch_image_repo_name
    }
    
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_helm.yml"
  }
}

# CodeBuildDFProject	container-devsecops-wksp-build-dockerfile	AWS::CodeBuild::Project	CREATE_COMPLETE	-
resource "aws_codebuild_project" "codebuild_df_project" {
  name          = "${var.name}-build-dockerfile"
  service_role  = aws_iam_role.codebuild_role.arn
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_dockerfile.yml"
  }
}

# CodeBuildPublishProject	container-devsecops-wksp-publish	AWS::CodeBuild::Project	CREATE_COMPLETE	-
resource "aws_codebuild_project" "codebuild_publish_project" {
  name          = "${var.name}-publish"
  service_role  = aws_iam_role.codebuild_role.arn
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      type  = "PLAINTEXT"
      value = var.prod_image_repo_name
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_push.yml"
  }
}

# CodeBuildSecretsProject	container-devsecops-wksp-build-secrets	AWS::CodeBuild::Project	CREATE_COMPLETE	-
resource "aws_codebuild_project" "codebuild_secrets_project" {
  name          = "${var.name}-build-secrets"
  service_role  = aws_iam_role.codebuild_role.arn
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "APP_REPO_URL"
      type  = "PLAINTEXT"
      value = var.app_repo_clone_url
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_secrets.yml"
  }
}

# CodeBuildVulnProject	container-devsecops-wksp-scan-image	AWS::CodeBuild::Project	CREATE_COMPLETE	-
resource "aws_codebuild_project" "codebuild_vuln_project" {
  name          = "${var.name}-scan-image"
  service_role  = aws_iam_role.codebuild_role.arn
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    
    environment_variable {
      name  = "FAIL_WHEN"
      type  = "PLAINTEXT"
      value = var.vulnerability_intolerance
    }
    
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      type  = "PLAINTEXT"
      value = var.scratch_image_repo_name
    }
    
    environment_variable {
      name  = "FUNCTION_ARN"
      value = var.lambda_security_hub_arn
    }
    
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_vuln.yml"
  }
}

# CodePipeline	container-devsecops-wksp-pipeline	AWS::CodePipeline::Pipeline	CREATE_COMPLETE	-
resource "aws_codepipeline" "codepipeline" {
  name      = "${var.name}-pipeline"
  role_arn  = aws_iam_role.codepipeline_role.arn
  
  artifact_store {
    location = aws_s3_bucket.pipeline_bucket.bucket
    type     = "S3"
  }
  
  stage {
    name = "PullRequest"
    
    action {
      name             = "AppSource"
      category         = "Source"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeCommit"
      # namespace        = "SourceVariables"
      output_artifacts = ["AppSource"]
      run_order        = 1

      configuration = {
        RepositoryName       = var.app_repository_name
        BranchName           = "dev"
        PollForSourceChanges = "false"
      }
    }
    
    action {
      name             = "ConfigSource"
      category         = "Source"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeCommit"
      # namespace        = "SourceVariables"
      output_artifacts = ["ConfigSource"]
      run_order        = 1

      configuration = {
        RepositoryName       = var.config_repository_name
        BranchName           = "main"
        PollForSourceChanges = "false"
      }
    }
    
    action {
      name             = "HelmSource"
      category         = "Source"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeCommit"
      # namespace        = "SourceVariables"
      output_artifacts = ["HelmSource"]
      run_order        = 1

      configuration = {
        RepositoryName       = var.helm_repository_name
        BranchName           = "main"
        PollForSourceChanges = "false"
      }
    }
    
  }
  
  stage {
    name = "StaticAnalysis-DockerfileConfiguration-Secrets"
    
    action {
      name             = "DockerfileValidation"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["AppSource","ConfigSource"]
      output_artifacts = ["DFAppSourceOutput","DFConfigSourceOutput"]
      run_order        = 1

      configuration = {
        ProjectName   = aws_codebuild_project.codebuild_df_project.name
        PrimarySource = "ConfigSource"
      }
    }
    
    action {
      name             = "SecretsValidation"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["AppSource","ConfigSource"]
      output_artifacts = ["SecretsAppSourceOutput","SecretsConfigSourceOutput"]
      run_order        = 1

      configuration = {
        ProjectName   = aws_codebuild_project.codebuild_secrets_project.name
        PrimarySource = "ConfigSource"
      }
    }
    
    action {
      name             = "ManifestValidation"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["AppSource","ConfigSource","HelmSource"]
      run_order        = 1

      configuration = {
        ProjectName   = aws_codebuild_project.codebuild_kubesec_project.name
        PrimarySource = "ConfigSource"
      }
    }
    
    action {
      name             = "SonarScan"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["AppSource","ConfigSource"]
      run_order        = 1

      configuration = {
        ProjectName   = aws_codebuild_project.codebuild_sonar_project.name
        PrimarySource = "ConfigSource"
      }
    }
  }
  
  stage {
    name = "VulnerabilityAnalysis"
    
    action {
      name             = "VulnerabilityScan"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["AppSource","ConfigSource"]
      output_artifacts = ["VulnAppSourceOutput","VulnConfigSourceOutput"]
      run_order        = 1

      configuration = {
        ProjectName   = aws_codebuild_project.codebuild_vuln_project.name
        PrimarySource = "ConfigSource"
      }
    }
  }
  
  stage {
    name = "DeployStageK8s"
    
    action {
      name             = "DeployK8s"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["AppSource","ConfigSource","HelmSource"]
      run_order        = 1

      configuration = {
        ProjectName   = aws_codebuild_project.codebuild_helm_project.name
        PrimarySource = "ConfigSource"
      }
    }
  }
  
  stage {
    name = "ZAPScan"
    
    action {
      name             = "ZAPScan"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["AppSource","ConfigSource","HelmSource"]
      run_order        = 1

      configuration = {
        ProjectName   = aws_codebuild_project.codebuild_zap_project.name
        PrimarySource = "ConfigSource"
      }
    }
  }
  
  stage {
    name = "PublishImage"
    
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["AppSource","ConfigSource"]
      output_artifacts = ["PushAppSourceOutput","PushConfigSourceOutput"]
      run_order        = 1

      configuration = {
        ProjectName   = aws_codebuild_project.codebuild_publish_project.name
        PrimarySource = "ConfigSource"
      }
    }
  }
}

# CodePipelineRole	container-devsecops-wksp-codepipeline-service 	AWS::IAM::Role	CREATE_COMPLETE	-
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.name}-codepipeline-service"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "codepipeline.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  path = "/"
  inline_policy {
    name = "ServicePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "codecommit:*",
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListObject"
          ]
          Resource = [
            aws_s3_bucket.pipeline_bucket.arn,
            "${aws_s3_bucket.pipeline_bucket.arn}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "codebuild:StartBuild",
            "codebuild:BatchGetBuilds"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

# LambdaCBKS	
data "archive_file" "lambda_cbks_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_cbks.py"
    output_path   = "${path.module}/lambda/lambda_cbks.zip"
}

resource "aws_lambda_function" "lambda_cbks" {
  function_name = "${var.name}-kubesec-scan"
  description = "Adds a comment to the pull request regarding the success or failure of manifest scan by kubesec"
  handler = "lambda_cbks.handler"
  environment {
    variables = {
      PREFIX = var.name
      CODEBUILDKSPROJECT = aws_codebuild_project.codebuild_kubesec_project.name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_cbks.zip"
  source_code_hash = data.archive_file.lambda_cbks_source_zip.output_base64sha256
}

# LambdaCBSO	
data "archive_file" "lambda_cbso_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_cbso.py"
    output_path   = "${path.module}/lambda/lambda_cbso.zip"
}

resource "aws_lambda_function" "lambda_cbso" {
  function_name = "${var.name}-sonar-scan"
  description = "Adds a comment to the pull request regarding the success or failure of SonarQube scan."
  handler = "lambda_cbso.handler"
  environment {
    variables = {
      PREFIX = var.name
      CODEBUILDSOPROJECT = aws_codebuild_project.codebuild_sonar_project.name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_cbso.zip"
  source_code_hash = data.archive_file.lambda_cbso_source_zip.output_base64sha256
}

# LambdaCBZP	
data "archive_file" "lambda_cbzp_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_cbzp.py"
    output_path   = "${path.module}/lambda/lambda_cbzp.zip"
}

resource "aws_lambda_function" "lambda_cbzp" {
  function_name = "${var.name}-zap-scan"
  description = "Adds a comment to the pull request regarding the success or failure of ZAP scan."
  handler = "lambda_cbzp.handler"
  environment {
    variables = {
      PREFIX = var.name
      CODEBUILDZPPROJECT = aws_codebuild_project.codebuild_zap_project.name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_cbzp.zip"
  source_code_hash = data.archive_file.lambda_cbzp_source_zip.output_base64sha256
}

# LambdaCBHM	
data "archive_file" "lambda_cbhm_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_cbhm.py"
    output_path   = "${path.module}/lambda/lambda_cbhm.zip"
}

resource "aws_lambda_function" "lambda_cbhm" {
  function_name = "${var.name}-helm-deploy"
  description = "Adds a comment to the pull request regarding the success or failure of the deployment to k8s cluster."
  handler = "lambda_cbhm.handler"
  environment {
    variables = {
      PREFIX = var.name
      CODEBUILDHMPROJECT = aws_codebuild_project.codebuild_helm_project.name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_cbhm.zip"
  source_code_hash = data.archive_file.lambda_cbhm_source_zip.output_base64sha256
}

# LambdaCBDF	container-devsecops-wksp-codebuild-dockerfile 	AWS::Lambda::Function	CREATE_COMPLETE	-
data "archive_file" "lambda_cbdf_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_cbdf.py"
    output_path   = "${path.module}/lambda/lambda_cbdf.zip"
}

resource "aws_lambda_function" "lambda_cbdf" {
  function_name = "${var.name}-codebuild-dockerfile"
  description = "Adds a comment to the pull request regarding the success or failure of the Dockerfile static analysis codebuild."
  handler = "lambda_cbdf.handler"
  environment {
    variables = {
      PREFIX = var.name
      CODEBUILDDFPROJECT = aws_codebuild_project.codebuild_df_project.name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_cbdf.zip"
  source_code_hash = data.archive_file.lambda_cbdf_source_zip.output_base64sha256
}

# LambdaCBPU	container-devsecops-wksp-codebuild-publish 	AWS::Lambda::Function	CREATE_COMPLETE	-
data "archive_file" "lambda_cbpu_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_cbpu.py"
    output_path   = "${path.module}/lambda/lambda_cbpu.zip"
}

resource "aws_lambda_function" "lambda_cbpu" {
  function_name = "${var.name}-codebuild-publish"
  description = "Adds a comment to the pull request regarding the success or failure of the publish codebuild project."
  handler = "lambda_cbpu.handler"
  environment {
    variables = {
      PREFIX = var.name
      CODEBUILDPUPROJECT = aws_codebuild_project.codebuild_publish_project.name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_cbpu.zip"
  source_code_hash = data.archive_file.lambda_cbpu_source_zip.output_base64sha256
}

# LambdaCBSC	container-devsecops-wksp-codebuild-secrets 	AWS::Lambda::Function	CREATE_COMPLETE	-
data "archive_file" "lambda_cbsc_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_cbsc.py"
    output_path   = "${path.module}/lambda/lambda_cbsc.zip"
}

resource "aws_lambda_function" "lambda_cbsc" {
  function_name = "${var.name}-codebuild-secrets"
  description = "Adds a comment to the pull request regarding the success or failure of the secrets analysis codebuild."
  handler = "lambda_cbsc.handler"
  environment {
    variables = {
      PREFIX = var.name
      CODEBUILDSCPROJECT = aws_codebuild_project.codebuild_secrets_project.name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_cbsc.zip"
  source_code_hash = data.archive_file.lambda_cbsc_source_zip.output_base64sha256
}

# LambdaCBVC	container-devsecops-wksp-codebuild-vulnerability 	AWS::Lambda::Function	CREATE_COMPLETE	-
data "archive_file" "lambda_cbvc_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_cbvc.py"
    output_path   = "${path.module}/lambda/lambda_cbvc.zip"
}

resource "aws_lambda_function" "lambda_cbvc" {
  function_name = "${var.name}-codebuild-vulnerability"
  description = "Adds a comment to the pull request regarding the success or failure of the vulnerability scanning codebuild."
  handler = "lambda_cbvc.handler"
  environment {
    variables = {
      PREFIX = var.name
      CODEBUILDVCPROJECT = aws_codebuild_project.codebuild_vuln_project.name
      IMAGEREPONAME = var.scratch_image_repo_name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_cbvc.zip"
  source_code_hash = data.archive_file.lambda_cbvc_source_zip.output_base64sha256
}

# LambdaPR	container-devsecops-wksp-pr 	AWS::Lambda::Function	CREATE_COMPLETE	-
data "archive_file" "lambda_pr_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_pr.py"
    output_path   = "${path.module}/lambda/lambda_pr.zip"
}
resource "aws_lambda_function" "lambda_pr" {
  function_name = "${var.name}-pr"
  description = "Adds an initial comment to the pull request."
  handler = "lambda_pr.handler"
  environment {
    variables = {
      PREFIX = var.name
    }
  }
  role = aws_iam_role.lambda_pr_comment_role.arn
  runtime = "python3.9"
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_pr.zip"
  source_code_hash = data.archive_file.lambda_pr_source_zip.output_base64sha256
}

# LambdaPRCommentRole	container-devsecops-wksp-lambda-pr 	AWS::IAM::Role	CREATE_COMPLETE	-
resource "aws_iam_role" "lambda_pr_comment_role" {
  name = "${var.name}-lambda-pr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  path = "/"
  inline_policy {
    name = "PRPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "codecommit:*",
            "codebuild:*",
            "codepipeline:StartPipelineExecution",
            "ssm:DescribeParameters",
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:PutParameter",
            "ssm:DeleteParameter",
            "ssm:DeleteParameters"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

# PermissionForEventsToInvokeLambdaCBZP
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_cbzp" {
  statement_id  = "PermissionForEventsToInvokeLambdaCBZP"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_cbzp.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cbzp_event_rule.arn
}

# PermissionForEventsToInvokeLambdaCBKS
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_cbks" {
  statement_id  = "PermissionForEventsToInvokeLambdaCBKS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_cbks.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cbks_event_rule.arn
}

# PermissionForEventsToInvokeLambdaCBSO
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_cbso" {
  statement_id  = "PermissionForEventsToInvokeLambdaCBSO"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_cbso.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cbso_event_rule.arn
}

# PermissionForEventsToInvokeLambdaCBHM
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_cbhm" {
  statement_id  = "PermissionForEventsToInvokeLambdaCBHM"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_cbhm.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cbhm_event_rule.arn
}

# PermissionForEventsToInvokeLambdaCBDF	container-dso-wksp-InitialPipeline-G9XL65A8YN8D-PermissionForEventsToInvokeLambdaCBDF-hVqqBQypRncu	AWS::Lambda::Permission	CREATE_COMPLETE	-
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_cbdf" {
  statement_id  = "PermissionForEventsToInvokeLambdaCBDF"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_cbdf.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cbdf_event_rule.arn
}

# PermissionForEventsToInvokeLambdaCBPU	container-dso-wksp-InitialPipeline-G9XL65A8YN8D-PermissionForEventsToInvokeLambdaCBPU-bWW4E1O85jpD	AWS::Lambda::Permission	CREATE_COMPLETE	-
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_cbpu" {
  statement_id  = "PermissionForEventsToInvokeLambdaCBPU"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_cbpu.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cbpu_event_rule.arn
}

# PermissionForEventsToInvokeLambdaCBSC	container-dso-wksp-InitialPipeline-G9XL65A8YN8D-PermissionForEventsToInvokeLambdaCBSC-kHunXJ5xo436	AWS::Lambda::Permission	CREATE_COMPLETE	-
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_cbsc" {
  statement_id  = "PermissionForEventsToInvokeLambdaCBSC"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_cbsc.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cbsc_event_rule.arn
}

# PermissionForEventsToInvokeLambdaCBVC	container-dso-wksp-InitialPipeline-G9XL65A8YN8D-PermissionForEventsToInvokeLambdaCBVC-tGsAMQGE4Vfw	AWS::Lambda::Permission	CREATE_COMPLETE	-
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_cbvc" {
  statement_id  = "PermissionForEventsToInvokeLambdaCBVC"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_cbvc.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cbvc_event_rule.arn
}

# PermissionForEventsToInvokeLambdaPR	container-dso-wksp-InitialPipeline-G9XL65A8YN8D-PermissionForEventsToInvokeLambdaPR-x7WbeHQQrQmX	AWS::Lambda::Permission	CREATE_COMPLETE	-
resource "aws_lambda_permission" "permission_for_event_to_invoke_lambda_pr" {
  statement_id  = "PermissionForEventsToInvokeLambdaPR"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_pr.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pr_event_rule.arn
}

# PipelineBucket	container-devsecops-wksp-460449571267-us-east-2-artifacts 	AWS::S3::Bucket	CREATE_COMPLETE	-
resource "aws_s3_bucket" "pipeline_bucket" {
  bucket = "${var.name}-${data.aws_caller_identity.current.account_id}-${var.region}-artifacts"
  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_encryption" {
  bucket = aws_s3_bucket.pipeline_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

# PREventRule	container-devsecops-wksp-pr 	AWS::Events::Rule	CREATE_COMPLETE	-
resource "aws_cloudwatch_event_rule" "pr_event_rule" {
  name = "${var.name}-pr"
  description = "Trigger notifications based on CodeCommit Pull Requests"
  event_pattern = jsonencode({
    source = [
      "aws.codecommit"
    ]
    detail-type = [
      "CodeCommit Pull Request State Change"
    ]
    resources = [
      var.app_repository_arn
    ]
    detail = {
      event = [
        "pullRequestSourceBranchUpdated",
        "pullRequestCreated"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "pr_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.pr_event_rule.name
  target_id = "${var.name}-pr"
  arn       = aws_lambda_function.lambda_pr.arn
}

# PREventRuleRole	container-devsecops-wksp-cloudwatch-pr 	AWS::IAM::Role	CREATE_COMPLETE	-
resource "aws_iam_role" "pr_event_rule_role" {
  name = "${var.name}-cloudwatch-pr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  path = "/"
  inline_policy {
    name = "PRPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "codepipeline:*"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_security_group" "codebuild_security_group" {
  name        = "${var.name}-codebuild-sg"
  description = "Security group for Codebuild project"
  vpc_id      = var.vpc_id
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_iam_role" "lambda_security_hub_import_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
  path = "/"
  inline_policy {
    name = "lambda-execution-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "securityhub:*"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

data "archive_file" "lambda_sechub_source_zip" {
    type          = "zip"
    source_file   = "${path.module}/lambda/lambda_sechub.py"
    output_path   = "${path.module}/lambda/lambda_sechub.zip"
}

resource "aws_lambda_function" "lambda_security_hub_import" {
  function_name = "${var.name}-import-to-securityhub"
  handler = "lambda_sechub.handler"
  role = aws_iam_role.lambda_security_hub_import_role.arn
  runtime = "python3.8"
  environment {
    variables = {
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
  }
  timeout = 35
  memory_size = 128
  filename = "${path.module}/lambda/lambda_sechub.zip"
  source_code_hash = data.archive_file.lambda_sechub_source_zip.output_base64sha256
  tags = var.tags
}

resource "aws_securityhub_account" "security_hub_setting" {}

# # CloudTrail
# resource "aws_s3_bucket" "trail_bucket" {
#   bucket = "${var.name}-trailbucket-${data.aws_caller_identity.current.account_id}"
#   tags = var.tags
# }

# resource "aws_s3_bucket_policy" "trail_bucket_policy" {
#   bucket = aws_s3_bucket.trail_bucket.id
#   policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Sid = "AWSCloudTrailAclCheck"
#           Effect = "Allow"
#           Principal = {
#             Service = "cloudtrail.amazonaws.com"
#           }
#           Action = "s3:GetBucketAcl"
#           Resource = "arn:aws:s3:::${aws_s3_bucket.trail_bucket.id}"
#         },
#         {
#           Sid = "AWSCloudTrailWrite"
#           Effect = "Allow"
#           Principal = {
#             Service = "cloudtrail.amazonaws.com"
#           }
#           Action = "s3:PutObject"
#           Resource = "arn:aws:s3:::${aws_s3_bucket.trail_bucket.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
#           Condition = {
#             StringEquals = {
#               "s3:x-amz-acl" = "bucket-owner-full-control"
#             }
#           }
#         },
#         {
#           Sid = "AllowSSLRequestsOnly"
#           Effect = "Deny"
#           Principal = "*"
#           Action = "s3:*"
#           Resource = "arn:aws:s3:::${aws_s3_bucket.trail_bucket.id}/*"
#           Condition = {
#             Bool = {
#               "aws:SecureTransport" = false
#             }
#           }
#         }
#       ]
#     }
#   )
# }

# resource "aws_cloudtrail" "trail" {
#   name = "${var.name}-CTrail"
#   s3_bucket_name = aws_s3_bucket.trail_bucket.id
#   include_global_service_events = true
#   is_multi_region_trail = true
#   enable_log_file_validation = true
#   cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail_log_group.arn}:*"
#   cloud_watch_logs_role_arn = aws_iam_role.trail_log_group_role.arn
# }

# resource "aws_cloudwatch_log_group" "trail_log_group" {
#   // CF Property(RetentionInDays) = 90
# }

# resource "aws_iam_role" "trail_log_group_role" {
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid = "AssumeRole1"
#         Effect = "Allow"
#         Principal = {
#           Service = "cloudtrail.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
#   inline_policy {
#     name = "cloudtrail-policy"
#     policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Effect = "Allow"
#           Action = [
#             "logs:CreateLogStream",
#             "logs:PutLogEvents"
#           ]
#           Resource = "${aws_cloudwatch_log_group.trail_log_group.arn}:*"
#         }
#       ]
#     })
#   }
# }

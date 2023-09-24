provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name     = basename(path.cwd)
  region   = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    blueprint  = local.name
    "auto-delete" = "no"
  }
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "type" = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "type" = "private"
  }

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.name
  })
}

module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 2.0"
  
  zones = {
    "devsecops-training.com" = {
      # in case than private and public zones with the same domain name
      domain_name = "devsecops-training.com"
      comment     = "private-vpc.devsecops-training.com"
      vpc = [
        {
          vpc_id = module.vpc.vpc_id
        }
      ]
      tags = {
        Name = "private-vpc.devsecops-training.com"
      }
    }
  }
}

module "k8s_cluster" {
  source                    = "./modules/k8s_cluster"
  region                    = local.region
  cluster_name              = local.name
  cluster_version           = "1.27"
  vpc_id                    = module.vpc.vpc_id
  node_subnet_ids           = module.vpc.private_subnets
  control_plane_subnet_ids  = module.vpc.public_subnets
  codebuild_role_arn        = module.pipeline.codebuild_role_arn
  tags                      = local.tags
}

# AppRepository	50e63d14-be19-4f65-b8c2-024dfba847b5	AWS::CodeCommit::Repository	CREATE_COMPLETE	-
resource "aws_codecommit_repository" "app_repository" {
  repository_name = "${local.name}-app"
  description     = "This is the application repository to support the container devsecops workshop"
  tags = local.tags
}

# ConfigRepository	a7e0e5dc-b84a-4da2-8dca-f095510e54ed	AWS::CodeCommit::Repository	CREATE_COMPLETE	-
resource "aws_codecommit_repository" "config_repository" {
  repository_name = "${local.name}-config"
  description     = "This is the configuration repository to support the container devsecops workshop"
  tags = local.tags
}

# helmRepository	a7e0e5dc-b84a-4da2-8dca-f095510e54ed	AWS::CodeCommit::Repository	CREATE_COMPLETE	-
resource "aws_codecommit_repository" "helm_repository" {
  repository_name = "${local.name}-helm"
  description     = "This is the helm repository for container devsecops workshop"
  tags = local.tags
}

# ScratchRepository	container-devsecops-wksp-scratch 	AWS::ECR::Repository	CREATE_COMPLETE	-
resource "aws_ecr_repository" "scratch_ecr_repository" {
  name                 = "scratch-${local.name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  
  tags = local.tags
}

# ECRRepository	container-devsecops-wksp-sample 	AWS::ECR::Repository	CREATE_COMPLETE	-
resource "aws_ecr_repository" "prd_ecr_repository" {
  name                 = "prod-${local.name}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = local.tags
}

module pipeline {
  source                    = "./modules/pipeline"
  region                    = local.region
  name                      = local.name
  app_repository_arn        = aws_codecommit_repository.app_repository.arn
  app_repository_name       = aws_codecommit_repository.app_repository.repository_name
  app_repo_clone_url        = aws_codecommit_repository.app_repository.clone_url_http
  config_repository_name    = aws_codecommit_repository.config_repository.repository_name
  helm_repository_name      = aws_codecommit_repository.helm_repository.repository_name
  prod_image_repo_name      = aws_ecr_repository.prd_ecr_repository.name
  scratch_image_repo_name   = aws_ecr_repository.scratch_ecr_repository.name
  vulnerability_intolerance = "HIGH"
  lambda_security_hub_arn   = aws_ecr_repository.prd_ecr_repository.arn
  tags                      = local.tags
}

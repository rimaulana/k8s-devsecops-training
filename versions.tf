terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }
  
  backend "local" {
    path = "/home/ec2-user/environment/terraform.tfstate"
  }
}
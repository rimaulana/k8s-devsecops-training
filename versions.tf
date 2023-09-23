terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }

   ##  Used for end-to-end testing on project; update to suit your needs
   backend "s3" {
     bucket = "gresik"
     region = "us-east-1"
     key    = "e2e/k8s-devsecops-training/terraform.tfstate"
   }
}
terraform {

  required_version = ">= 1.10"

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

  }

  backend "s3" {
    bucket       = "3tiers-app-terraform-state"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-3"
    use_lockfile = true
    encrypt      = true
  }

}

provider "aws" {

  region = var.aws_region

}
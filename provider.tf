terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.25"
    }
  }
}

provider "aws" {
  profile = "litebreeze"
  region  = var.aws_region
}

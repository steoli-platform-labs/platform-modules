terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.7.0, < 3.0.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

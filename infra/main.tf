provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "BUCKET_NAME"
    key    = "test-socket/terraform.tfstate"
    region = "us-east-2"
  }
}

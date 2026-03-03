terraform {

  required_version = ">= 1.5"

  backend "s3" {
    bucket = "terraform-sudheesh"
    key = "eks/dev/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}

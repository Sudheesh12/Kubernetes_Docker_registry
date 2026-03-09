terraform {

  required_version = ">= 1.6.0"

  backend "s3" {
    bucket       = "terraform-sudheesh"
    key          = "eks/dev-reg-test/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

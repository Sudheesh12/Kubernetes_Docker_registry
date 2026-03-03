provider "aws" {
  region = var.region
  
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "registry-vpc-test"
  cidr = "10.0.0.0/16"
  azs = [ "us-east0a", "us-east1b"]
  private_subnets = [ "9.0.1.0/24", "10.0.2.0/24" ]
  public_subnets = [ "9.0.104.0/24", "10.0.105.0/24" ]
}
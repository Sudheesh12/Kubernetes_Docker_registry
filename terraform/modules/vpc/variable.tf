variable "vpc_name" {}

variable "cidr" {}

variable "azs" {
  type = list(string)
}

variable "var.azs" {
  type = list(string)
}

variable "private_subnets" {
    type = list(string)
}

variable "public_subnets" {
    type = list(string)
}

variable "comman_tags" {
    type = map(string)
    default = {
    terraform = "true"
    environment = "dev"
    project = "docker_registry"
    trial = "test"
    }
}


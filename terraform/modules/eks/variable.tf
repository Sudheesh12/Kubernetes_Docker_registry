variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
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
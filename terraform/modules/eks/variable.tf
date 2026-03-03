variable "vpc_id" {
}
variable "cluster_name" {
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
variable "role_name" {}
  
variable "oidc_provider" {}

variable "role_policy_arns" {
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
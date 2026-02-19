variable "resource_group_name" {
  type    = string
  default = "my-llmops-rg"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "acr_name" {
  type    = string
  default = "acrllmops"
}

variable "containerapp_env_name" {
  type    = string
  default = "llmops-env"
}

variable "containerapp_name" {
  type    = string
  default = "llmops-api"
}

variable "image_uri" {
  type    = string
  default = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "container_app_enabled" {
  type    = bool
  default = true
}

variable "cpu" {
  type    = number
  default = 0.25
}

variable "memory" {
  type    = string
  default = "0.5Gi"
}

variable "min_replicas" {
  type    = number
  default = 0
}

variable "max_replicas" {
  type    = number
  default = 1
}

variable "target_port" {
  type    = number
  default = 8000
}

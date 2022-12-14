## Service account variables

variable "credentials" {
  type = string
}

## Account variables

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "create_load_balancer" {
  type    = bool
  default = false
}

locals {
  environment  = terraform.workspace
  service_name = "ping-explorer"
  image_name   = "${local.service_name}-${local.environment}"
}

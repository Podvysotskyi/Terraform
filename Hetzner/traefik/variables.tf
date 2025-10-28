variable "DOCKER_HOST" {
  description = "Docker Host"
  type        = string
}

variable "CLOUDFLARE_EMAIL" {
  type = string
}

variable "CLOUDFLARE_TOKEN" {
  type      = string
  sensitive = true
}

variable "CLOUDFLARE_DOMAIN" {
  type = string
}
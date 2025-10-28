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

variable "HETZNER_IP" {
  type      = string
  sensitive = true
}

resource "docker_network" "traefik_docker_network" {
  name = "traefik"

  attachable = true
  internal   = true
}

resource "docker_image" "traefik_docker_image" {
  name = "traefik:v3.3"
}

resource "docker_volume" "letsencrypt_docker_volume" {
  name = "traefik-letsencrypt"
}

resource "docker_volume" "config_docker_volume" {
  name = "traefik-config"
}

resource "docker_container" "traefik_docker_container" {
  image    = docker_image.traefik_docker_image.image_id
  name     = "traefik"
  hostname = "traefik"
  must_run = true
  restart  = "unless-stopped"

  command = concat([
    "--api.insecure=true",
    "--providers.docker=true",
    "--providers.docker.exposedbydefault=false",
    "--providers.file.directory=/etc/traefik",
    "--entryPoints.web.address=:80",
    "--entryPoints.websecure.address=:443",
    "--certificatesresolvers.cloudflare.acme.email=${var.CLOUDFLARE_EMAIL}",
    "--certificatesresolvers.cloudflare.acme.dnschallenge.provider=cloudflare",
    "--certificatesresolvers.cloudflare.acme.storage=/letsencrypt/acme.json",
    "--serversTransport.insecureSkipVerify=true",
  ])

  cpu_shares        = 0
  ipc_mode          = "private"
  log_driver        = "json-file"
  max_retry_count   = 0
  memory            = 0
  memory_swap       = 0
  network_mode      = "bridge"
  privileged        = false
  publish_all_ports = false

  ports = [
    {
      internal = 80
      external = 80
      protocol = "tcp"
    },
    {
      internal = 443
      external = 443
      protocol = "tcp"
    }
  ]

  volumes = [
    {
      container_path = "/var/run/docker.sock"
      host_path      = "/var/run/docker.sock"
      read_only      = true
    },
    {
      container_path = "/letsencrypt"
      volume_name    = docker_volume.letsencrypt_docker_volume.name
    },
    {
      container_path = "/etc/traefik"
      volume_name    = docker_volume.config_docker_volume.name
    },
  ]

  networks_advanced = [
    {
      name = docker_network.traefik_docker_network.name
    }
  ]

  labels = [
    {
      key   = "traefik.enable"
      value = "true"
    },
    {
      key   = "traefik.docker.network"
      value = docker_network.traefik_docker_network.name
    },
    # WEB
    {
      key   = "traefik.http.routers.traefik-web.entrypoints"
      value = "web"
    },
    {
      key   = "traefik.http.routers.traefik-web.rule"
      value = "Host(`traefik.${var.CLOUDFLARE_DOMAIN}`)"
    },
    {
      key   = "traefik.http.routers.traefik-web.service"
      value = "traefik-web"
    },
    {
      key   = "traefik.http.services.traefik-web.loadbalancer.server.port"
      value = "8080"
    },
    {
      key   = "traefik.http.services.traefik-web.loadbalancer.server.scheme"
      value = "http"
    },
    {
      key   = "traefik.http.services.traefik-web.loadbalancer.passhostheader"
      value = "true"
    },
    {
      key   = "traefik.http.routers.traefik-web.middlewares"
      value = "https-redirect"
    },
    # WEBSECURE
    {
      key   = "traefik.http.routers.traefik-websecure.entrypoints"
      value = "websecure"
    },
    {
      key   = "traefik.http.routers.traefik-websecure.rule"
      value = "Host(`traefik.${var.CLOUDFLARE_DOMAIN}`)"
    },
    {
      key   = "traefik.http.routers.traefik-websecure.tls.certResolver"
      value = "cloudflare"
    },
    {
      key   = "traefik.http.routers.traefik-websecure.service"
      value = "traefik-web"
    }
  ]

  env = [
    "CLOUDFLARE_DNS_API_TOKEN=${var.CLOUDFLARE_TOKEN}",
  ]
}


terraform {
  required_version = ">= 0.13.0"
  backend "cloud" {
    organization = "dsilva"
    workspaces {
      name = "k3s-kubernetes"
    }
  }
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

locals {
  kube_config = yamldecode(file("${path.module}/${var.kubeconfig}"))
}

provider "helm" {
  kubernetes {
    host                   = local.kube_config.clusters[0].cluster.server
    cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
    client_certificate     = base64decode(local.kube_config.users[0].user.client-certificate-data)
    client_key             = base64decode(local.kube_config.users[0].user.client-key-data)
  }
}
provider "kubernetes" {
  host                   = local.kube_config.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
  client_certificate     = base64decode(local.kube_config.users[0].user.client-certificate-data)
  client_key             = base64decode(local.kube_config.users[0].user.client-key-data)
}
provider "kubectl" {
  config_path      = var.kubeconfig
  load_config_file = true
}

# Configure cloudflare access
provider "cloudflare" {
  api_token = var.cloudflare_token
}

# Deploy longhorn
module "longhorn" {
  source = "./longhorn-storage"
  # We cannot use the external DNS from cloudflare module, otherwise
  # we get a loop error. Longhorn needs to be the first thing that is deployed
  externaldns_target = "${var.cloudflare_tunnel_name}.${var.cloudflare_dns_zone}"
  hostname           = "longhorn.${var.cloudflare_dns_zone}"
}

# Call the module to setup a cloudflare tunnel,
# and external DNS
module "cloudflared" {
  depends_on             = [module.longhorn]
  source                 = "./cloudflared"
  cloudflare_zone_id     = var.cloudflare_zone_id
  cloudflare_account_id  = var.cloudflare_account_id
  cloudflare_email       = var.cloudflare_email
  cloudflare_token       = var.cloudflare_token
  cloudflare_tunnel_name = var.cloudflare_tunnel_name
  cloudflare_dns_zone    = var.cloudflare_dns_zone
}


# Deploy traefik custom configs and dashboard
module "traefik" {
  source             = "./traefik"
  externaldns_target = module.cloudflared.cloudflare_tunnel_dns
  hostname           = "traefik.${var.cloudflare_dns_zone}"
}

# Deploy authelia for SSO (Single Sign-On)
module "authelia" {
  source             = "./authelia-idm"
  externaldns_target = module.cloudflared.cloudflare_tunnel_dns
  hostname           = "sso.${var.cloudflare_dns_zone}"
}

# # # Deploy ArgoCD
# # # Currently comment out as not needed. Kept for future
# # # reference
# # # module "argocd" {
# # #   source                 = "./argocd"
# # #   cloudflare_dns_zone    = var.cloudflare_dns_zone
# # #   cloudflare_tunnel_name = var.cloudflare_tunnel_name
# # #   depends_on             = [module.cloudflared]
# # # }

# # Deploy uptime kuma
# # module "uptimekuma" {
# #   source                  = "./uptimekuma"
# #   externaldns_target      = module.cloudflared.cloudflare_tunnel_dns
# #   hostname                = "uptime.${var.cloudflare_dns_zone}"
# #   traefik_auth_middleware = module.authentik.traefik_auth_middleware
# # }

# # # Deploy homepage
# # module "homepage" {
# #   source                  = "./benphelps_homepage"
# #   externaldns_target      = module.cloudflared.cloudflare_tunnel_dns
# #   hostname                = "lab.${var.cloudflare_dns_zone}"
# #   coinmarketcap_api_key   = var.coinmarketcap_api_key
# #   cloudflare_account_id   = var.cloudflare_account_id
# #   cloudflare_token        = var.cloudflare_token
# #   cloudflare_tunnel_id    = module.cloudflared.cloudflare_tunnel_id
# #   traefik_auth_middleware = module.authentik.traefik_auth_middleware
# # }


# # # Deploy pihole
# # module "pihole" {
# #   source                  = "./pi-hole"
# #   externaldns_target      = module.cloudflared.cloudflare_tunnel_dns
# #   hostname                = "pihole.${var.cloudflare_dns_zone}"
# #   traefik_auth_middleware = module.authentik.traefik_auth_middleware
# # }

# # # # Deploy kubernetes dashboard
# # # module "kubernetes_dashboard" {
# # #   source                  = "./kubernetes_dashboard"
# # #   hostname                = "kubernetes-dashboard.${var.cloudflare_dns_zone}"
# # #   traefik_auth_middleware = module.authentik.traefik_auth_middleware
# # #   externaldns_target      = module.cloudflared.cloudflare_tunnel_dns
# # # }

# # # Deploy monitoring stack (Prometheus + Grafana + Node exporter + Alert manager)
# # module "monitoring-stack" {
# #   source                  = "./monitoring-stack"
# #   externaldns_target      = module.cloudflared.cloudflare_tunnel_dns
# #   grafana_hostname        = "grafana.${var.cloudflare_dns_zone}"
# #   prometheus_hostname     = "prometheus.${var.cloudflare_dns_zone}"
# #   alert_manager_hostname  = "alert-manager.${var.cloudflare_dns_zone}"
# #   traefik_auth_middleware = module.authentik.traefik_auth_middleware
# #   servers_ips             = var.server_ips
# # }

# # # Deploy vaultwarden
# # # module "vaultwarden" {
# # #   source             = "./vaultwarden-password-manager"
# # #   externaldns_target = module.cloudflared.cloudflare_tunnel_dns
# # #   hostname           = "vaultwarden.${var.cloudflare_dns_zone}"
# # # }
# # # Deploy internet speedtest tracker
# # module "speedtest-tracker" {
# #   source                  = "./speedtest-tracker"
# #   externaldns_target      = module.cloudflared.cloudflare_tunnel_dns
# #   hostname                = "speedtest.${var.cloudflare_dns_zone}"
# #   traefik_auth_middleware = module.authentik.traefik_auth_middleware
# # }
# # # # Deploy obsidian
# # # module "obsidian" {
# # #   source                  = "./obsidian-md"
# # #   externaldns_target      = module.cloudflared.cloudflare_tunnel_dns
# # #   hostname                = "obsidian.${var.cloudflare_dns_zone}"
# # #   traefik_auth_middleware = module.authentik.traefik_auth_middleware
# # # }
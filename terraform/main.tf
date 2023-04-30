terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    bucket                      = "terraform-states"
    key                         = "k3s-dsilva-dev.tfstate"
    endpoint                    = "https://s3-api.dsilva.dev"
    force_path_style            = true
    region                      = "eu-south-2"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# Configure cloudflare access
provider "cloudflare" {
  api_token = var.cloudflare_token
}



# Call the module to setup the proxmox nodes
# and start the kubernetes cluster
module "proxmox-nodes" {
  source                   = "./proxmox"
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_api_url          = var.proxmox_api_url
  server_node_count        = var.server_node_count
  cluster_name             = var.cluster_name
  k3s_version              = var.k3s_version
  disk_size                = var.disk_size
  memory                   = var.memory
  cores                    = var.cores
  ciuser                   = var.ciuser
  ssh_keys                 = var.ssh_keys
  ssh_private_key          = var.ssh_private_key
}

# Configure both kubernetes and helm with kubeconfig path
provider "helm" {
  kubernetes {
    config_path = "./kubeconfig"
  }
}
provider "kubernetes" {
  config_path = "./kubeconfig"
}

# Call the module to setup a cloudflare tunnel,
# and external DNS
module "cloudflared" {
  source                 = "./cloudflared"
  cloudflare_zone_id     = var.cloudflare_zone_id
  cloudflare_account_id  = var.cloudflare_account_id
  cloudflare_email       = var.cloudflare_email
  cloudflare_token       = var.cloudflare_token
  cloudflare_tunnel_name = var.cloudflare_tunnel_name
  cloudflare_dns_zone = var.cloudflare_dns_zone
  depends_on          = [module.proxmox-nodes]

}

# Call the module to setup ArgoCD
module "argocd" {
  source                 = "./argocd"
  cloudflare_dns_zone    = var.cloudflare_dns_zone
  cloudflare_tunnel_name = var.cloudflare_tunnel_name
  depends_on             = [module.cloudflared]
}



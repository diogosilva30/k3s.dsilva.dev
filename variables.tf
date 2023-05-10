#########################################
# Variables required for "proxmox" module
#########################################
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}
variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}
variable "proxmox_api_url" {
  type      = string
  sensitive = true
}
variable "worker_node_count" {
  description = "The number of worker nodes in the kubernetes cluster."
  default     = 3
}
variable "server_node_count" {
  description = "The number of server nodes in the kubernetes cluster (odd number required)."
  default     = 4
}
variable "k3s_version" {
  description = "The version of k3s"
  type        = string
  default     = "v1.26.3+k3s1"
}

# Hardware configuration for kubernetes nodes
variable "disk_size" {
  description = "The disk size. E.g. '50G'"
  type        = string
  default     = "30G"
}
variable "memory" {
  description = "The ammount of memory. E.g. '2048'"
  type        = number
  default     = 3072 # 3GB of RAM
}
variable "cores" {
  description = "The number of CPU cores of the VM"
  type        = number
  default     = 4
}
# SSH configuration
variable "ciuser" {
  description = "The name of the default user that should be created"
  type        = string
}
variable "ssh_keys" {
  description = "The SSH key to add to the VM"
  type        = string
}
variable "ssh_private_key" {
  description = "The private SSH key for terraform to SSH into the machine"
  sensitive   = true
  type        = string
}

##########################################
# Variables required for "cloudflare" and
# "argocd" module
##########################################

variable "cloudflare_tunnel_name" {
  description = "The name of the Cloudflare tunnel"
  type        = string
}
variable "cloudflare_dns_zone" {
  type        = string
  default     = "dsilva.dev"
  description = "The cloudflare DNS zone (e.g. yourdomain.com)"
}
variable "cloudflare_zone_id" {
  description = "Zone ID for your domain"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Account ID for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Email address for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "cloudflare_token" {
  description = "Cloudflare API token created at https://dash.cloudflare.com/profile/api-tokens"
  type        = string
}

##########################################
# Other variables
##########################################
variable "coinmarketcap_api_key" {
  type      = string
  sensitive = true
}
variable "authentik_api_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Authentik API key that we can after the first deploy for Homepage integration widget"
}
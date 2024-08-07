
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
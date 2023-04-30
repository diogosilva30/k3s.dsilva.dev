# ArgoCD server
variable "argocd_chart_version" {
  type    = string
  default = "4.9.8"
}

variable "argocd_chart_name" {
  type    = string
  default = "argo-cd"
}
variable "cloudflare_tunnel_name" {
  description = "Name of the cloudflared tunnel"
  type        = string
}
variable "cloudflare_dns_zone" {
  description = "The cloudflare DNS zone (e.g. yourdomain.com)"
  type        = string
}
# variable "kubeconfig_file_path" {
#   type        = string
#   description = "The path for the KUBECONFIG"
# }



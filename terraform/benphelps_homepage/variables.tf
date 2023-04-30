variable "externaldns_target" {
  type = string
}
variable "hostname" {
  type = string
}
variable "namespace" {
  type    = string
  default = "homepage"
}
variable "coinmarketcap_api_key" {
  type      = string
  sensitive = true
}
variable "cloudflare_account_id" {
  type      = string
  sensitive = true
}
variable "cloudflare_tunnel_id" {
  type = string
}
variable "cloudflare_token" {
  type      = string
  sensitive = true
}

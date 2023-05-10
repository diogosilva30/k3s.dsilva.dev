variable "externaldns_target" {
  type = string
}
variable "hostname" {
  type = string
}
variable "namespace" {
  type    = string
  default = "authentik"
}
variable "authentik_middleware_name" {
  type    = string
  default = "authentik"
}
variable "authentik_api_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Authentik API key that we can after the first deploy for Homepage integration widget"
}
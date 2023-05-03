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
variable "namespace" {
  type    = string
  default = "vaultwarden"
}
variable "externaldns_target" {
  type = string
}
variable "hostname" {
  type = string
}
variable "traefik_auth_middleware" {
  type = string
}
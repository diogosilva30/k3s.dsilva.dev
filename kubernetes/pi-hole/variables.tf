variable "externaldns_target" {
  type = string
}
variable "hostname" {
  type = string
}
variable "namespace" {
  type    = string
  default = "pihole"
}
variable "service_name" {
  type    = string
  default = "pihole-svc"
}
variable "pihole_admin_middleware_name" {
  type    = string
  default = "pihole-admin"
}
variable "traefik_auth_middleware" {
  type = string
}
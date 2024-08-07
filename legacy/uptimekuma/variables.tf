variable "externaldns_target" {
  type = string
}
variable "hostname" {
  type = string
}
variable "namespace" {
  type    = string
  default = "kuma"
}
variable "service_name" {
  type    = string
  default = "uptime-kuma-svc"
}
variable "traefik_auth_middleware" {
  type = string
}
variable "externaldns_target" {
  type = string
}
variable "hostname" {
  type = string
}
variable "traefik_auth_middleware" {
  type = string
}
variable "namespace" {
  type    = string
  default = "speedtest-tracker"
}
variable "service_name" {
  type    = string
  default = "speedtest"
}
variable "deployment_name" {
  type    = string
  default = "speedtest"
}
variable "database_name" {
  type    = string
  default = "speedtest"
}

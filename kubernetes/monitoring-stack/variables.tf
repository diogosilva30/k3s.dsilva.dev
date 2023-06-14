variable "namespace" {
  type    = string
  default = "monitoring"
}
variable "externaldns_target" {
  type = string
}
variable "grafana_hostname" {
  type = string
}
variable "prometheus_hostname" {
  type = string
}
variable "alert_manager_hostname" {
  type = string
}
variable "traefik_auth_middleware" {
  type = string
}
variable "servers_ips" {
  type = list(string)
}
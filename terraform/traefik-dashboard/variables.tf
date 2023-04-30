variable "externaldns_target" {
  type = string
}
variable "hostname" {
  type = string
}
variable "namespace" {
  type    = string
  default = "kube-system"
}
variable "service_name" {
  type    = string
  default = "traefik-dashboard-svc"

}
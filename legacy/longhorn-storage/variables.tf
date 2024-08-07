variable "namespace" {
  type    = string
  default = "longhorn-system"
}
variable "externaldns_target" {
  type = string
}
variable "hostname" {
  type = string
}
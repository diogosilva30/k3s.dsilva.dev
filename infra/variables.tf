
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}
variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}
variable "proxmox_api_url" {
  type      = string
  sensitive = true
}
variable "node_count" {
  description = "The number of the kubernetes cluster nodes (the first 2 will always be server nodes for High-Availability)."
  default     = 5
}
variable "k3s_version" {
  description = "The version of k3s"
  type        = string
  default     = "v1.26.3+k3s1"
}
# Hardware configuration for kubernetes nodes
variable "disk_size" {
  description = "The disk size. E.g. '50G'"
  type        = string
  default     = "30G"
}
variable "memory" {
  description = "The ammount of memory. E.g. '2048'"
  type        = number
  default     = 3072
}
variable "balloon" {
  description = <<EOF
  The minimum amount of memory to allocate to the VM in Megabytes, when
  Automatic Memory Allocation is desired. Proxmox will enable a balloon device on the guest to manage
  EOF
  type        = number
  default     = 1024
}
variable "cores" {
  description = "The number of CPU cores of the VM"
  type        = number
  default     = 4
}
# SSH configuration
variable "ciuser" {
  description = "The name of the default user that should be created"
  type        = string
}
variable "ssh_keys" {
  description = "The SSH key to add to the VM"
  type        = string
}
variable "ssh_private_key" {
  description = "The private SSH key for terraform to SSH into the machine"
  sensitive   = true
  type        = string
}



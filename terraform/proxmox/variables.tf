
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

variable "server_node_count" {
  description = "The number of server nodes in the kubernetes cluster (odd number required)."
  default     = 3
}
variable "cluster_name" {
  type    = string
  default = "services"
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
}
variable "memory" {
  description = "The ammount of memory. E.g. '2048'"
  type        = number
}
variable "cores" {
  description = "The number of CPU cores of the VM"
  type        = number
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


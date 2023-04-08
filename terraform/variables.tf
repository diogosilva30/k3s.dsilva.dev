
# Define variables for connection with proxmox
# server
variable "proxmox_api_url" {
  type = string
}
variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}
variable "worker_node_count" {
  description = "The number of worker nodes in the kubernetes cluster."
  default     = 2
}
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
variable "nameserver" {
  description = "The name server for the VM"
  type        = string
  default     = "8.8.8.8"
}
variable "disk_size" {
  description = "The disk size. E.g. '50G'"
  type        = string
  default     = "10G"
}
variable "memory" {
  description = "The ammount of memory. E.g. '2048'"
  type        = number
  default     = 1024 # 512mb of RAM
}
variable "cores" {
  description = "The number of CPU cores of the VM"
  type        = number
  default     = 1
}

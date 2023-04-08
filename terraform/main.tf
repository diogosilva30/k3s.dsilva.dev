terraform {
  required_version = ">= 0.13.0"
  # Initialize the local backend
  required_providers {
    # https://github.com/Telmate/terraform-provider-proxmox
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.3"
    }

  }
  backend "s3" {
    bucket                      = "terraform-states"
    key                         = "services-dsilva-dev.tfstate"
    endpoint                    = "https://s3-api.dsilva.dev"
    force_path_style            = true
    region                      = "eu-south-2"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }

}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
  pm_log_enable       = true
  pm_log_file         = "terraform-plugin-proxmox.log"
  pm_debug            = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}


# Control plane node
resource "proxmox_vm_qemu" "k3s-control-plane-node" {
  name        = "k3s-master"
  desc        = "Kubernetes control plane node for services.dsilva.dev"
  target_node = "proxmox"

  # Hardware configuration
  agent   = 1
  clone   = "ubuntu-server-22"
  cores   = var.cores
  memory  = var.memory
  sockets = 1
  cpu     = "host"
  disk {
    storage = "local"
    type    = "virtio"
    size    = var.disk_size
  }

  os_type         = "cloud-init"
  ipconfig0       = "ip=dhcp" # auto-assign a IP address for the machine
  nameserver      = var.nameserver
  ciuser          = var.ciuser
  sshkeys         = var.ssh_keys
  ssh_user        = var.ciuser
  ssh_private_key = var.ssh_private_key

  # Specify connection variables for remote execution
  connection {
    type        = "ssh"
    host        = self.ssh_host # Auto-assigned ip address
    user        = self.ssh_user
    private_key = self.ssh_private_key
    port        = self.ssh_port
  }


  provisioner "local-exec" {
    command = <<-EOT
          echo "${self.ssh_private_key}" > privkey
          chmod 600 privkey
          echo ${self.ssh_user}
          echo ${self.ssh_host}
          k3sup install --ip ${self.ssh_host} --ssh-key privkey --user ${self.ssh_user} --k3s-version v1.26.3+k3s1
        EOT
  }
}

# Create the worker nodes
resource "proxmox_vm_qemu" "k3s-worker-nodes" {

  # Only start creating worker nodes after control plane
  # node is ready
  depends_on = [
    proxmox_vm_qemu.k3s-control-plane-node,
  ]

  name        = "k3s-worker-1"
  desc        = "Kubernetes worker node 1 for services.dsilva.dev"
  target_node = "proxmox"

  # Hardware configuration
  agent   = 1
  clone   = "ubuntu-server-22"
  cores   = var.cores
  memory  = var.memory
  sockets = 1
  cpu     = "host"
  disk {
    storage = "local"
    type    = "virtio"
    size    = var.disk_size
  }

  os_type         = "cloud-init"
  ipconfig0       = "ip=dhcp" # auto-assign a IP address for the machine
  nameserver      = var.nameserver
  ciuser          = var.ciuser
  sshkeys         = var.ssh_keys
  ssh_user        = var.ciuser
  ssh_private_key = var.ssh_private_key

  # Specify connection variables for remote execution
  connection {
    type        = "ssh"
    host        = self.ssh_host # Auto-assigned ip address
    user        = self.ssh_user
    private_key = self.ssh_private_key
    port        = self.ssh_port
  }

  # Create the k3s cluster
  provisioner "local-exec" {
    command = <<-EOT
      echo "${self.ssh_private_key}" > privkey
      chmod 600 privkey
      echo ${self.ssh_host}
      echo ${proxmox_vm_qemu.k3s-control-plane-node.ssh_host}
      echo ${self.ssh_user}

      k3sup join --ip ${self.ssh_host} --server-ip=${proxmox_vm_qemu.k3s-control-plane-node.ssh_host} --ssh-key privkey --user ${self.ssh_user} --k3s-version v1.26.3+k3s1
    EOT

  }
}





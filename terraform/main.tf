terraform {
  required_version = ">= 0.13.0"
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
  required_providers {
    # https://github.com/Telmate/terraform-provider-proxmox
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.3"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
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


resource "proxmox_vm_qemu" "k3s-server-nodes" {

  count       = 1
  name        = "${var.cluster_name}-k3s-server-node-${count.index + 1}"
  desc        = "Kubernetes server node ${count.index + 1} for ${var.cluster_name}"
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
  nameserver      = "8.8.8.8"
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

  # Start the cluster
  provisioner "local-exec" {
    command = <<-EOT
      echo "${self.ssh_private_key}" > privkey
      chmod 600 privkey
      k3sup install --ip ${self.ssh_host} --user ${self.ssh_user} --ssh-key privkey --k3s-version ${var.k3s_version}
      EOT
  }

}


resource "proxmox_vm_qemu" "k3s-worker-nodes" {

  count       = var.worker_node_count
  name        = "${var.cluster_name}-k3s-worker-${count.index + 1}"
  desc        = "Kubernetes worker node ${count.index + 1} for ${var.cluster_name}"
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
  nameserver      = "8.8.8.8"
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

  # Join the cluster with k3sup
  provisioner "local-exec" {
    command = <<-EOT
      echo "${self.ssh_private_key}" > privkey
      chmod 600 privkey
      k3sup join --ip ${self.ssh_host} --server-ip=${proxmox_vm_qemu.k3s-server-nodes[0].ssh_host} --ssh-key privkey --user ${self.ssh_user} --k3s-version ${var.k3s_version}
    EOT

  }

}


resource "proxmox_vm_qemu" "k3s-server-nodes" {
  count       = var.server_node_count
  name        = "k3s-server-node-${count.index}"
  desc        = "Kubernetes server node ${count.index}"
  target_node = "proxmox"

  # Hardware configuration
  agent   = 1
  clone   = "ubuntu-server-jammy"
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
    timeout     = "10m"

  }

  # Provision the kubernetes cluster with k3sup
  provisioner "local-exec" {
    command = <<-EOT
      echo "${self.ssh_private_key}" > privkey
      chmod 600 privkey
      # If the first VM start the cluster, following VMs join it
      if [ "${count.index}" -eq 0 ]; then
        echo Installing first node 
        k3sup install --ip ${self.ssh_host} --user ${self.ssh_user} --ssh-key privkey --k3s-version ${var.k3s_version} --cluster
      else
        echo installing other node
        k3sup join --ip ${self.ssh_host} --user ${self.ssh_user} --server-user ${self.ssh_user} --ssh-key privkey --k3s-version ${var.k3s_version} --server-ip ${proxmox_vm_qemu.k3s-server-nodes[0].ssh_host} --server
      fi

      # # Wait for the k3s service to start
      until ssh -o "StrictHostKeyChecking no" -i privkey ${self.ssh_user}@${self.ssh_host} sudo systemctl status k3s | grep "Active: active"; do
        sleep 5
      done
      EOT

  }
  # For some reason terraform has changes on reapply
  # https://github.com/Telmate/terraform-provider-proxmox/issues/112
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

}

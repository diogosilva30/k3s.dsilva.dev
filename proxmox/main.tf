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
  balloon = 1024
  sockets = 1
  cpu     = "host"
  disk {
    storage = "local"
    type    = "virtio"
    size    = var.disk_size
  }

  os_type         = "cloud-init"
  ipconfig0       = "ip=dhcp" # auto-assign a IP address for the machine
  nameserver      = "1.1.1.1"
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

      # Wait for the k3s service to start
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

resource "null_resource" "configure_dns_servers" {
  # This configuration is needed because we will deploy Pihole as DNS on port 53
  # and the VM will be unable to perform DNS lookups because the default nameserver
  # is "127.0.0.53". We need to set it to an upstream server such as Google, Cloudflare
  count = var.server_node_count
  # Trigger to always run this resource
  triggers = {
    always_run = timestamp()
  }
  # And run only after nodes have been provisioned
  depends_on = [proxmox_vm_qemu.k3s-server-nodes]

  # Specify connection variables for remote execution
  connection {
    type        = "ssh"
    host        = proxmox_vm_qemu.k3s-server-nodes[count.index].ssh_host
    user        = proxmox_vm_qemu.k3s-server-nodes[count.index].ssh_user
    private_key = proxmox_vm_qemu.k3s-server-nodes[count.index].ssh_private_key
    port        = proxmox_vm_qemu.k3s-server-nodes[count.index].ssh_port
    timeout     = "10m"
  }
  provisioner "remote-exec" {
    inline = [
      # Based on https://askubuntu.com/a/1346001
      # Make sure cloudflare is setup as nameserver, otherwise apt update and install commands wont work
      "if ! grep -q 'nameserver 1.1.1.1' /etc/resolv.conf; then echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf; fi",
      "sudo apt update -y",
      "sudo apt install resolvconf -y",
      # Only add nameservers to file if they don't exist already
      "grep -qxF 'nameserver 1.1.1.1' /etc/resolvconf/resolv.conf.d/head || echo 'nameserver 1.1.1.1' | sudo tee -a /etc/resolvconf/resolv.conf.d/head",
      "grep -qxF 'nameserver 8.8.8.8' /etc/resolvconf/resolv.conf.d/head || echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolvconf/resolv.conf.d/head",
      "sudo systemctl restart resolvconf.service",
      "sudo systemctl restart systemd-resolved"
    ]
  }
}


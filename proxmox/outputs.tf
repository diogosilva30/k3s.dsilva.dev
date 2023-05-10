# Export the path of the cluster kubeconfig
# By default k3sup exports it to the path "./kubeconfig"
output "kubeconfig_file_path" {
  value = "./kubeconfig"
}
output "server_ips" {
  value = proxmox_vm_qemu.k3s-server-nodes.*.ssh_host
}
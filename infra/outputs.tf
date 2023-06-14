# Export the path of the cluster kubeconfig
output "kubeconfig_file_path" {
  value = local.kubeconfig_path
}
output "server_ips" {
  value = proxmox_vm_qemu.k3s-nodes.*.ssh_host
}
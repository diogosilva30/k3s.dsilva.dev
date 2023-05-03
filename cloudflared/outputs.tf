output "cloudflare_tunnel_dns" {
  value = cloudflare_record.tunnel.hostname
}
output "cloudflare_tunnel_id" {
  value = cloudflare_tunnel.tunnel.id
}
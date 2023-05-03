output "traefik_auth_middleware" {
  description = "Returns the string that should be used to reference the created forward auth middleware"
  value       = "${var.namespace}-${var.authentik_middleware_name}@kubernetescrd"
}
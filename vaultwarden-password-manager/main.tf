# Install Prometheus with grafana dashboards
resource "helm_release" "vaultwarden" {
  name             = "vaultwarden"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://gissilabs.github.io/charts/"
  chart            = "vaultwarden"

  values = [
    templatefile("${path.module}/values.yaml",
      {
        externaldns_target      = var.externaldns_target
        traefik_auth_middleware = var.traefik_auth_middleware
        hostname                = var.hostname
      }
    )
  ]
}
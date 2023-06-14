# Install Prometheus with grafana dashboards
resource "helm_release" "longhorn" {
  name             = "longhorn"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"

  values = [
    templatefile("${path.module}/values.yaml",
      {
        hostname                = var.hostname
        externaldns_target      = var.externaldns_target
      }
    )
  ]
}
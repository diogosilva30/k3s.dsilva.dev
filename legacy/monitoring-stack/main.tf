# Install Prometheus with grafana dashboards
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"

  values = [
    templatefile("${path.module}/values.yaml",
      {
        grafana_hostname        = var.grafana_hostname
        alert_manager_hostname  = var.alert_manager_hostname
        prometheus_hostname     = var.prometheus_hostname
        servers_ips             = var.servers_ips
        externaldns_target      = var.externaldns_target
        traefik_auth_middleware = var.traefik_auth_middleware
      }
    )
  ]
}
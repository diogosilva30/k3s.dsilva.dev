


# Deploys authentik using an helm chart
resource "helm_release" "pihole" {
  name             = "pihole"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://mojo2600.github.io/pihole-kubernetes/"
  chart            = "pihole"

  values = [
    templatefile("${path.module}/values.yaml",
      {
        hostname                = var.hostname,
        externaldns_target      = var.externaldns_target,
        traefik_auth_middleware = var.traefik_auth_middleware,
        pihole_admin_middleware = "${var.namespace}-${var.pihole_admin_middleware_name}@kubernetescrd",
        service_name            = var.service_name
      }
    )
  ]
}


# Pihole UI runs under /admin subpath and any request
# to "/" (root path) gets a Lighttpd server package placeholder
# page. To fix this, we create a traefik middleware to redirect all
# requests "/" to "/admin" 
resource "kubectl_manifest" "pihole_admin_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
    name: ${var.pihole_admin_middleware_name}
    namespace: ${helm_release.pihole.namespace}
spec:
  redirectRegex:
    regex: "^https?://${var.hostname}/?$"
    replacement: "https://${var.hostname}/admin"
    permanent: true
  YAML
}
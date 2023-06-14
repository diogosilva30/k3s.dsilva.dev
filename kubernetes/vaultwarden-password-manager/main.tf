# Create a random token for the admin panel
resource "random_id" "admin_token" {
  byte_length = 35
}
resource "kubectl_manifest" "vaultwarden-namespace" {
  yaml_body = <<YAML
kind: Namespace
apiVersion: v1
metadata:
  name: ${var.namespace}
  YAML
}

# Create kubernetes secrets to hold the generated admin token
resource "kubernetes_secret" "vaultwarden_admin_token" {
  metadata {
    name = "vaultwarden-admin-token"
    # Create in the same namespace as the helm install
    namespace = var.namespace
  }

  data = {
    admin-token = base64encode(random_id.admin_token.b64_std)
  }
  type = "kubernetes.io/secret"
}
# Install Vaultwarden using helm
resource "helm_release" "vaultwarden" {
  name       = "vaultwarden"
  namespace  = var.namespace
  repository = "https://gissilabs.github.io/charts/"
  chart      = "vaultwarden"

  values = [
    templatefile("${path.module}/values.yaml",
      {
        externaldns_target = var.externaldns_target
        hostname           = var.hostname
        secret_name        = kubernetes_secret.vaultwarden_admin_token.metadata[0].name
      }
    )
  ]
}

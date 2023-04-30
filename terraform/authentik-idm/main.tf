# Generates a 35-character secret for the postgres password.
resource "random_id" "postgres_password" {
  byte_length = 35
}
# and another one for authentik secret key
resource "random_id" "authentik_secret_key" {
  byte_length = 35
}


# Deploys authentik using an helm chart
resource "helm_release" "authentik" {
  name             = "authentik"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://charts.goauthentik.io"
  chart            = "authentik"

  values = [
    templatefile("${path.module}/values.yaml",
      {
        hostname           = var.hostname,
        externaldns_target = var.externaldns_target,
        # Pass the generated values for the `values.yaml`
        authentik_secret_key = random_id.authentik_secret_key.b64_std,
        postgres_password    = random_id.postgres_password.b64_std
      }
    )
  ]
}


# Create kubernetes secrets to hold the generated secrets
resource "kubernetes_secret" "postgres_password" {
  metadata {
    name = "postgres-password"
    # Create in the same namespace as the helm install
    namespace = helm_release.authentik.namespace
  }

  data = {
    postgres-password = base64encode(random_id.postgres_password.b64_std)
  }

  type = "kubernetes.io/secret"
}
resource "kubernetes_secret" "authentik_secret_key" {
  metadata {
    name = "authentik-secret-key"
    # Create in the same namespace as the helm install
    namespace = helm_release.authentik.namespace
  }

  data = {
    postgres-password = base64encode(random_id.authentik_secret_key.b64_std)
  }

  type = "kubernetes.io/secret"
}
# https://www.reddit.com/r/selfhosted/comments/wre8ua/authentiktraefikk8sfluxcd_because_documentation/
# Generates a 35-character secret for the postgres password.
resource "random_id" "postgres_password" {
  byte_length = 35
}
# and another one for authentik secret key
resource "random_id" "authentik_secret_key" {
  byte_length = 35
}

# Split the provide hostname e.g. "sso.yourdomain.com"
# to get the "yourdomain.com" part
locals {
  hostname_parts    = split(".", var.hostname)
  domain_name_parts = slice(local.hostname_parts, 1, 3)
  domain            = join(".", local.domain_name_parts)
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
        domain             = local.domain,
        # Pass the generated values for the `values.yaml`
        authentik_secret_key = random_id.authentik_secret_key.b64_std,
        postgres_password    = random_id.postgres_password.b64_std
        authentik_api_key    = var.authentik_api_key
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
    authentik-secret-key = base64encode(random_id.authentik_secret_key.b64_std)
  }

  type = "kubernetes.io/secret"
}

# We match any subdomain on the current domain with path
# "/outpost.goauthentik.io/" and forward it to authentik output
# service
resource "kubectl_manifest" "authentik-outpost-ingress" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: authentik-outpost
  namespace: ${helm_release.authentik.namespace}
  annotations:
    kubernetes.io/ingress.class: traefik
    external-dns.alpha.kubernetes.io/target: "${var.externaldns_target}"
spec:
  rules:
    - host: "*.${local.domain}"
      http:
        paths:
          - path: "/outpost.goauthentik.io/"
            pathType: Prefix
            backend:
              service:
                name: ak-outpost-authentik-embedded-outpost
                port:
                  number: 9000

  YAML
}
# Create the traefik middleware for forward auth
# against authentik
# https://goauthentik.io/docs/providers/proxy/server_traefik
# Our middleware sends to the "/outpost.goauthentik.io/auth/traefik"
# path which is handled by our above ingress
resource "kubectl_manifest" "traefik-middleware" {
  yaml_body = <<YAML
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
    name: ${var.authentik_middleware_name}
    namespace: ${helm_release.authentik.namespace}
spec:
  forwardAuth:
      address: "https://${var.hostname}/outpost.goauthentik.io/auth/traefik"
      trustForwardHeader: true
      authResponseHeaders:
          - X-authentik-username
          - X-authentik-groups
          - X-authentik-email
          - X-authentik-name
          - X-authentik-uid
          - X-authentik-jwt
          - X-authentik-meta-jwks
          - X-authentik-meta-outpost
          - X-authentik-meta-provider
          - X-authentik-meta-app
          - X-authentik-meta-version
  YAML
}

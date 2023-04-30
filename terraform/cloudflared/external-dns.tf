# This Terraform file creates a Kubernetes namespace called "external-dns" and deploys ExternalDNS on it, using Helm.
# ExternalDNS is a Kubernetes addon that automatically configures DNS records for Kubernetes Services and Ingresses.
# In this case, ExternalDNS is configured to use Cloudflare as the DNS provider, and a Cloudflare API token is stored
# in a Kubernetes secret.
# The "zoneIdFilters" set in the Helm release configuration restrict ExternalDNS to only modify DNS records for a
# specific Cloudflare Zone ID.
# The policy is set to "sync", which means that ExternalDNS will synchronize DNS records to match the desired state.


# This block defines a Kubernetes namespace called "external-dns".
#It specifies the metadata for the namespace, including its name, labels, and annotations.
resource "kubernetes_namespace" "external_dns" {
  metadata {
    name        = "external-dns"
    annotations = {}
    labels      = {}
  }
}

# This block deploys ExternalDNS on the "external-dns" namespace created in the previous block, using Helm. 
# It specifies the repository and chart to use for the installation, as well as the namespace to install into.
# It also sets several values using the "set" block. The first "set" sets the provider to "cloudflare".
# The second "set" sets the secretName to the Kubernetes secret created in the next block, which contains the Cloudflare API token.
# The third "set" sets the zoneIdFilters to the Cloudflare Zone ID provided as a Terraform variable.
# The fourth "set" sets the policy to "sync", which means that ExternalDNS will synchronize DNS records to match the desired state.
resource "helm_release" "external_dns" {
  name = "external-dns"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"

  namespace = kubernetes_namespace.external_dns.metadata[0].name

  set {
    name  = "provider"
    value = "cloudflare"
  }

  set {
    name  = "cloudflare.secretName"
    value = kubernetes_secret.external_dns.metadata[0].name
  }

  set {
    name  = "zoneIdFilters.${var.cloudflare_zone_id}"
    value = var.cloudflare_zone_id
  }

  set {
    name  = "policy"
    value = "sync"
  }
}

# This block creates a Kubernetes secret called "external-dns", which contains the Cloudflare API token. 
# It specifies the namespace to create the secret in, which is the "external-dns" namespace created in the first block.
# The data block specifies the data to store in the secret, in this case the Cloudflare API token.
# The type block specifies the type of the secret, in this case "kubernetes.io/secret".
resource "kubernetes_secret" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = kubernetes_namespace.external_dns.metadata[0].name
  }

  data = {
    "cloudflare_api_token" = var.cloudflare_token
  }

  type = "kubernetes.io/secret"
}
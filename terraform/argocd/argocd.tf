# Install argocd on the k3s cluster
module "argocd" {
  # https://github.com/aigisuk/terraform-kubernetes-argocd
  source  = "aigisuk/argocd/kubernetes"
  version = "0.2.7"
  # Disable TLS on argo server itself, otherwise we get
  # infinite redirect issue.
  # https://github.com/argoproj/argo-cd/issues/2953
  insecure = true
}



# Define an ingress for argo cd UI to be accesible 
resource "kubernetes_ingress_v1" "argocd-ingress" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"

    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
      # This is really important! Sets correct CNAME to the Cloudflare Tunnel record
      "external-dns.alpha.kubernetes.io/target" = format("%s.%s", var.cloudflare_tunnel_name, var.cloudflare_dns_zone)
    }
  }

  spec {
    rule {
      host = "argocd.${var.cloudflare_dns_zone}"

      http {
        path {
          path = "/"

          backend {
            service {
              name = "argocd-server"
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [module.argocd]
}

# This Terraform file deploys a Kubernetes deployment, config map, namespace, and secret for Cloudflared.
# The namespace is named "cloudflared" and is used for the Cloudflared deployment.
# The deployment uses a Docker image from Cloudflare and creates two replicas. 
# It mounts two volumes (creds and config) with credentials and configuration data. 
# It also sets up a liveness probe that checks if the deployment is ready to serve traffic.
# The config map provides configuration data for the Cloudflared deployment, including 
# the ID of the Cloudflared tunnel and ingress rules for routing traffic to the correct services.
# The secret stores credentials for the Cloudflared deployment, including the account tag, 
# tunnel ID, tunnel name, and tunnel secret.

resource "kubernetes_namespace" "cloudflared" {
  metadata {
    name        = "cloudflared"
    annotations = {}
    labels      = {}
  }
}

resource "kubernetes_config_map" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace.cloudflared.metadata[0].name
  }

  data = {
    "config.yaml" = <<EOT
# Name of the tunnel you want to run
tunnel: ${cloudflare_tunnel.tunnel.id}
credentials-file: /etc/cloudflared/creds/credentials.json
# Serves the metrics server under /metrics and the readiness server under /ready
metrics: 0.0.0.0:2000
# Autoupdates applied in a k8s pod will be lost when the pod is removed or restarted, so
# autoupdate doesn't make sense in Kubernetes. However, outside of Kubernetes, we strongly
# recommend using autoupdate.
no-autoupdate: true
# The `ingress` block tells cloudflared which local service to route incoming
# requests to. For more about ingress rules, see
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/ingress
#
ingress:
# This rule sends all requests to traefik ingress controller, which proxies them further to correct services
- service: http://traefik.kube-system.svc.cluster.local:80
EOT
  }
}

resource "kubernetes_secret" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace.cloudflared.metadata[0].name
  }

  data = {
    "credentials.json" = jsonencode({
      "AccountTag"   = var.cloudflare_account_id,
      "TunnelID"     = cloudflare_tunnel.tunnel.id,
      "TunnelName"   = cloudflare_tunnel.tunnel.name,
      "TunnelSecret" = cloudflare_tunnel.tunnel.secret
    })
  }

  type = "kubernetes.io/secret"
}


resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace.cloudflared.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "cloudflared"
      }
    }

    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
      }

      spec {
        volume {
          name = "creds"
          secret {
            secret_name = "cloudflared"
          }
        }

        volume {
          name = "config"
          config_map {
            name = "cloudflared"
          }
        }

        container {
          image = "cloudflare/cloudflared:2023.4.2"
          name  = "cloudflared"
          args  = ["tunnel", "--config", "/etc/cloudflared/config/config.yaml", "run"]

          liveness_probe {
            http_get {
              path = "/ready"
              port = 2000
            }

            initial_delay_seconds = 1
            period_seconds        = 10
            failure_threshold     = 1
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/cloudflared/config"
            read_only  = true
          }

          volume_mount {
            name       = "creds"
            mount_path = "/etc/cloudflared/creds"
            read_only  = true
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_config_map.cloudflared,
    kubernetes_secret.cloudflared
  ]
}



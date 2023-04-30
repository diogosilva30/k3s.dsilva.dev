resource "helm_release" "benphelps_homepage" {
  name             = "homepage"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://jameswynn.github.io/helm-charts/"
  chart            = "homepage"

  values = [
    templatefile("${path.module}/values.yaml",
      {
        coinmarketcap_api_key = var.coinmarketcap_api_key,
        hostname              = var.hostname,
        externaldns_target    = var.externaldns_target,
        cloudflare_account_id = var.cloudflare_account_id,
        cloudflare_token      = var.cloudflare_token,
        cloudflare_tunnel_id  = var.cloudflare_tunnel_id,
      }
    )
  ]
}
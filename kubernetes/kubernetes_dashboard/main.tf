# Deploy kubernetes dashboard using helm
# https://github.com/kubernetes/dashboard
# https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard

# Deploys dashboard with helm chart
resource "helm_release" "kubernetes_dashboard" {
  name             = "kubernetes-dashboard"
  namespace        = "kubernetes-dashboard"
  create_namespace = true
  repository       = "https://kubernetes.github.io/dashboard/"
  chart            = "kubernetes-dashboard"

  set {
    name  = "service.externalPort"
    value = 9090
  }
  set {
    name  = "name"
    value = "kubernetes-dashboard"
  }
}


resource "kubectl_manifest" "kubernetes_dashboard_ingress" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${helm_release.kubernetes_dashboard.name}
  namespace: ${helm_release.kubernetes_dashboard.namespace}
  annotations:
    kubernetes.io/ingress.class: "traefik"
    traefik.ingress.kubernetes.io/ssl-redirect: "true"
    external-dns.alpha.kubernetes.io/target: "${var.externaldns_target}"
    # Protect service with SSO
    traefik.ingress.kubernetes.io/router.middlewares: ${var.traefik_auth_middleware}
    gethomepage.dev/enabled: "true"
    gethomepage.dev/description: Kubernetes dashboard for entire cluster monitoring and overview
    gethomepage.dev/group: Monitoring
    gethomepage.dev/icon: kubernetes.png
    gethomepage.dev/name: Kubernetes Dashboard
spec:
  rules:
    - host: ${var.hostname}
      http:
        paths:
          - backend:
              service:
                name: "kubernetes-dashboard"
                port:
                  number: 9090
            path: /
            pathType: Prefix
  YAML
}

locals {
  rbac_username = "admin-user"
}

resource "kubectl_manifest" "rbac" {
  # We need to setup an RBAC user
  # https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
  # To then get a token run:
  # kubectl -n kubernetes-dashboard create token admin-user
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${local.rbac_username}
  namespace: ${helm_release.kubernetes_dashboard.namespace}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${local.rbac_username}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: ${local.rbac_username}
  namespace: ${helm_release.kubernetes_dashboard.namespace}
  YAML
}
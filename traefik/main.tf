# https://medium.com/@_jonas/traefik-kubernetes-ingress-and-x-forwarded-headers-82194d319b0e
# We need to enable X-Forwarded-* headers, otherwise authentik fails with CSRF 500 error:
# https://github.com/goauthentik/authentik/issues/4209#issuecomment-1359533153
resource "kubectl_manifest" "traefik-config-override" {
  yaml_body = <<YAML
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    additionalArguments:
      - "--entryPoints.web.forwardedHeaders.insecure"
      - "--serversTransport.insecureSkipVerify=true"
    providers:
      kubernetesCRD:
        allowCrossNamespace: true
  YAML
}



resource "kubectl_manifest" "traefik-dashboard" {
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: ${var.service_name}
  namespace: ${var.namespace}
  labels:
    app.kubernetes.io/instance: traefik
    app.kubernetes.io/name: traefik-dashboard
spec:
  type: ClusterIP
  ports:
  - name: traefik
    port: 9000
    targetPort: traefik
    protocol: TCP
  selector:
    app.kubernetes.io/instance: traefik-kube-system
    app.kubernetes.io/name: traefik
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traefik-ingress
  namespace: ${var.namespace}
  annotations:
    kubernetes.io/ingress.class: traefik
    external-dns.alpha.kubernetes.io/target: "${var.externaldns_target}"
    gethomepage.dev/enabled: "true"
    gethomepage.dev/description: Traefik management dashboard
    gethomepage.dev/group: Monitoring
    gethomepage.dev/icon: traefik.png
    gethomepage.dev/name: Traefik
spec:
  rules:
    - host: ${var.hostname}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${var.service_name}
                port:
                  number: 9000

  YAML
}


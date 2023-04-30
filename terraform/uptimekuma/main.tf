resource "kubectl_manifest" "uptimekuma" {
  yaml_body = <<YAML
kind: Namespace
apiVersion: v1
metadata:
  name: ${var.namespace}
---
apiVersion: v1
kind: Service
metadata:
  name: ${var.service_name}
  namespace: ${var.namespace}
spec:
  selector:
    app: uptime-kuma
  ports:
  - name: uptime-kuma
    port: 3001
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: uptime-kuma
  namespace: ${var.namespace}
spec:
  replicas: 1
  serviceName: ${var.service_name}
  selector:
    matchLabels:
      app: uptime-kuma
  template:
    metadata:
      labels:
        app: uptime-kuma
    spec:
      containers:
        - name: uptime-kuma
          image: louislam/uptime-kuma:1.21.2
          env:
            - name: UPTIME_KUMA_PORT
              value: "3001"
            - name: PORT
              value: "3001"
          ports:
            - name: uptime-kuma
              containerPort: 3001
              protocol: TCP
          volumeMounts:
            - name: kuma-data
              mountPath: /app/data

  volumeClaimTemplates:
    - metadata:
        name: kuma-data
      spec:
        accessModes: ["ReadWriteOnce"]
        volumeMode: Filesystem
        resources:
          requests:
            storage: 1Gi
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: uptime-kuma
  namespace: ${var.namespace}
  annotations:
    kubernetes.io/ingress.class: "traefik"
    external-dns.alpha.kubernetes.io/target: "${var.externaldns_target}"
    gethomepage.dev/enabled: "true"
    gethomepage.dev/description: Downtime monitoring service
    gethomepage.dev/group: Monitoring
    gethomepage.dev/icon: uptime-kuma.png
    gethomepage.dev/name: Up Time Kuma
spec:
  rules:
    - host: ${var.hostname}
      http:
        paths:
          - backend:
              service:
                name: ${var.service_name}
                port:
                  number: 3001
            path: /
            pathType: Prefix

  YAML
}


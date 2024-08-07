# Kubernetes manifests to deploy internet speed tracker:
# https://github.com/alexjustesen/speedtest-tracker

# Generate random user name and password for the database connection
resource "random_id" "postgres_user" {
  byte_length = 35
}
resource "random_id" "postgres_password" {
  byte_length = 35
}

# Kubernetes namespace
resource "kubectl_manifest" "speedtest-tracker-namespace" {
  yaml_body = <<YAML
kind: Namespace
apiVersion: v1
metadata:
  name: ${var.namespace}
  YAML
}

# Save both the user and password into kubernetes secrets
resource "kubernetes_secret" "postgres_password" {
  metadata {
    name = "postgres-credentials"
    # Create in the same namespace as the helm install
    namespace = var.namespace
  }

  data = {
    postgres-user     = base64encode(random_id.postgres_password.b64_std),
    postgres-password = base64encode(random_id.postgres_password.b64_std)
  }

  type = "kubernetes.io/secret"
  # Requires namespace to exist first
  depends_on = [kubectl_manifest.speedtest-tracker-namespace]
}


# Kubernetes service
resource "kubectl_manifest" "speedtest-tracker-service" {
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: ${var.service_name}
  namespace: ${var.namespace}
spec:
  ports:
    - port: 8000
      targetPort: 80
  selector:
    app: ${var.deployment_name}
    YAML
}

# Kubernetes deployement
resource "kubectl_manifest" "speedtest-tracker-deployment" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${var.deployment_name}
  namespace: ${var.namespace}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${var.deployment_name}
  template:
    metadata:
      labels:
        app: ${var.deployment_name}
    spec:
      containers:
        - name: ${var.deployment_name}
          image: ghcr.io/alexjustesen/speedtest-tracker:latest
          ports:
            - containerPort: 80
              name: http
          env:
            - name: PUID
              value: "1000"
            - name: PGID
              value: "1000"
            - name: DB_CONNECTION
              value: pgsql
            - name: DB_HOST
              value: db
            - name: DB_PORT
              value: "5432"
            - name: DB_DATABASE
              value: ${var.database_name}
            - name: DB_USERNAME
              value: ${random_id.postgres_user.b64_std}
            - name: DB_PASSWORD
              value: ${random_id.postgres_password.b64_std}
          resources:
            limits:
              cpu: "1"
              memory: "512Mi"
      restartPolicy: Always
  YAML
}


# Kubernetes statefulset for the postgres database
resource "kubectl_manifest" "speedtest-tracker-database-statefulset" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
  namespace: ${var.namespace}
spec:
  replicas: 1
  serviceName: db
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
        - name: db
          image: postgres:15
          env:
            - name: POSTGRES_DB
              value: ${var.database_name}
            - name: POSTGRES_USER
              value: ${random_id.postgres_user.b64_std}
            - name: POSTGRES_PASSWORD
              value: ${random_id.postgres_password.b64_std}
          resources:
            limits:
              cpu: "1"
              memory: "512Mi"
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain
    whenScaled: Retain
  volumeClaimTemplates:
    - metadata:
        name: postgresql-db-disk
      spec:
        accessModes: ["ReadWriteMany"]
        storageClassName: "longhorn"
        resources:
          requests:
            storage: 5Gi
  YAML
}

# Database service so the speedtest tracker application can connect to it
resource "kubectl_manifest" "speedtest-tracker-database-service" {
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: ${var.namespace}
spec:
  ports:
    - name: postgres
      port: 5432
      targetPort: 5432
  selector:
    app: db
  YAML
}


# Finally, the kubernetes ingress so we can access our service
# on the defined hostname
resource "kubectl_manifest" "speedtest-tracker-ingress" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: speedtest-tracker
  namespace: ${var.namespace}
  annotations:
    kubernetes.io/ingress.class: "traefik"
    external-dns.alpha.kubernetes.io/target: "${var.externaldns_target}"
    # Protect service with SSO
    traefik.ingress.kubernetes.io/router.middlewares: ${var.traefik_auth_middleware}
    gethomepage.dev/enabled: "true"
    gethomepage.dev/description: Internet speed test tracking
    gethomepage.dev/group: Monitoring
    gethomepage.dev/icon: openspeedtest.png
    gethomepage.dev/name: Speed Test Tracker
    gethomepage.dev/widget.type: speedtest
    # use internal cluster url to bypass SSO authentication
    gethomepage.dev/widget.url: http://${var.service_name}.${var.namespace}.svc.cluster.local:8000
spec:
  rules:
    - host: ${var.hostname}
      http:
        paths:
          - backend:
              service:
                name: ${var.service_name}
                port:
                  number: 8000 # Port defined in our service
            path: /
            pathType: Prefix
  YAML
}
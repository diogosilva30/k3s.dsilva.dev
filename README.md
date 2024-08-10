
# 👋 Welcome to k3s.dsilva.dev :test_tube:

  
# Steps:

```shell
export PRIVATEKEY="private.key"
export PUBLICKEY="public.crt"
export NAMESPACE="sealed-secrets"
export SECRETNAME="keys"

openssl req -x509 -days 358000 -nodes -newkey rsa:4096 -keyout "$PRIVATEKEY" -out "$PUBLICKEY" -subj "/CN=sealed-secret/O=sealed-secret"

kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" create secret tls "$SECRETNAME" --cert="$PUBLICKEY" --key="$PRIVATEKEY"
kubectl -n "$NAMESPACE" label secret "$SECRETNAME" sealedsecrets.bitnami.com/sealed-secrets-key=active
```

### This open-source repository showcases a fully automated homelab k3s cluster on Proxmox, managed with Terraform and ArgoCD :rocket: 

  

## 🛠️ Provisioning the Infrastructure

To provision the entire infrastructure, follow the steps below:

  

1. Clone the repository:

```bash

git clone  https://github.com/diogosilv30/k3s.dsilva.dev.git

```

  

2. Navigate to the cloned directory:

```bash
cd  k3s.dsilva.dev
:
```

3. Define the following environment variables:
```shell
export  TF_VAR_proxmox_api_url=
export  TF_VAR_proxmox_api_token_id=
export  TF_VAR_proxmox_api_token_secret=
export  TF_VAR_ciuser=
export  TF_VAR_ssh_keys=
export  TF_VAR_ssh_private_key=
# Cloudflare variables
export  TF_VAR_cloudflare_dns_zone=yourdomain.com
export  TF_VAR_cloudflare_zone_id=
export  TF_VAR_cloudflare_account_id=
export  TF_VAR_cloudflare_email=
export  TF_VAR_cloudflare_token=

```
There are other variables you can configure, refer to `terraform/variables.tf` file.
  

4. Finally, run the following command to provision the infrastructure:

```shell

make apply

```

Easy peasy! :fire: :rocket: This command will create all the VMs (Kubernetes nodes) on Proxmox, set up the Cloudflare tunnel, configure ArgoCD, and deploy external-dns.

Once the infrastructure is provisioned, you can start deploying your services using ArgoCD and YAML manifests.

Inside the `terraform` folder you should find your `kubeconfig` file.

To use it do: `export KUBECONFIG=./terraform/kubeconfig`

Then you can interact with your cluster via `kubectl`.

To login into ArgoCD the default username is `admin` and the default password can be found using: 

`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo`

  

## 🚀 Technologies

  

- Terraform for Infrastructure as Code (IaC)

- Proxmox for virtualization

- Kubernetes (k3s) for container orchestration

- Cloudflare for DNS management and edge connectivity

- ArgoCD for GitOps-style deployment

- External-dns for seamless DNS integration with Kubernetes

- Github Actions pipeline for automated deployment

- Tailscale VPN for secure connection to home network

  

## 📦 Infrastructure as Code

With Terraform, all VMs are created on Proxmox automatically. This means you can quickly deploy and manage your k3s cluster with ease, without the need for manual intervention.

  

## 🌐 Cloudflare Integration

The Cloudflare tunnel is automated and configured to connect the Kubernetes cluster to the Cloudflare edge. This integration is also linked with external-dns, so that all DNS records are automatically updated with the correct IP addresses.

  

## 🚀 GitOps Deployment

ArgoCD is deployed with Terraform to enable GitOps-style deployment. This means that you can deploy and manage your services using YAML manifests, with minimal manual intervention.

  

## 🔒 Secure Connection

Using Github Actions pipeline, the deployment of infrastructure is fully automated by connecting the Github runner to my home network using Tailscale VPN. This ensures that all communication is secure and encrypted.

  

## 🙌 Contributing

If you'd like to contribute to this project, please feel free to submit a pull request. We welcome all contributions, big or small!

  

Thank you for checking out k3s.dsilva.dev!
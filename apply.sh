# !/bin/bash
set -e # Fail if any of the commands fails


echo "Applying infrastructure"
terraform -chdir=infra apply \
		-auto-approve \
		-input=false \
        -parallelism=1 \
		-var-file=vars.tfvars

# Extract kubeconfig from output
kubeconfig=$(terraform -chdir=infra output -raw kubeconfig_file_path)
# Copy the kubeconfig file to the kubernetes folder
eval "cp infra/$kubeconfig kubernetes/$kubeconfig"
# Move the kubeconfig to the default location so kubectl can be used
eval "cp infra/$kubeconfig ~/.kube/config"
# Deploy the kubernetes resources
terraform -chdir=kubernetes apply \
		-auto-approve \
		-input=false \
		-var server_ips=$(terraform -chdir=infra output -json server_ips) \
		-var kubeconfig=$kubeconfig \
		-var-file=vars.tfvars
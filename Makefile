# The apply command needs to be run in two parts. The first part builds the
# VMs (k3s nodes) and exports a kubeconfig, while the second part reads the
# exported kubeconfig so that the Kubernetes providers can use it.
# We also need "parallelism=1" due to proxmox nodes crashing
# when multiple nodes are joining the cluster in parallel with ectd
apply:
	terraform -chdir=terraform apply -target=module.proxmox-nodes -auto-approve -input=false --parallelism=1
	terraform -chdir=terraform apply -auto-approve -input=false --parallelism=1
destroy:
	terraform -chdir=terraform destroy -auto-approve -input=false
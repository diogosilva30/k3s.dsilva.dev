#!/bin/bash

# Parse command line options
key="$1"
kubeconfig=$(terraform -chdir=infra output -raw kubeconfig_file_path)
case $key in
        "--infra")
                # Cleanup kubernetes first
                echo "Cleaning up kubernetes resources"
                terraform -chdir=kubernetes destroy \
                    -auto-approve \
                    -input=false \
                    -var-file=vars.tfvars \
                    -var server_ips=$(terraform -chdir=infra output -json server_ips) \
		            -var kubeconfig=$kubeconfig
                echo "Cleaning up infrastructure"
                terraform -chdir=infra destroy -auto-approve -input=false -var-file=vars.tfvars
                ;;
        "--kubernetes")
                echo "Cleaning up kubernetes resources"
                terraform -chdir=kubernetes destroy \
                    -auto-approve \
                    -input=false \
                    -var-file=vars.tfvars \
                    -var server_ips=$(terraform -chdir=infra output -json server_ips) \
		            -var kubeconfig=$kubeconfig
                ;;
esac

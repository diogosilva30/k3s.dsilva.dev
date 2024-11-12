#!/bin/bash
# Usage: ./hack/setup_argocd.sh -t $GIT_TOKEN -r $GIT_REPO -c $CLUSTER_NAME

GIT_REPO=$(git config --get remote.origin.url)
CLUSTER_NAME="homelab"
echo "GIT_REPO: $GIT_REPO"

# Function to setup ArgoCD Autopilot
setup_argocd_autopilot() {
    echo "Setting up ArgoCD Autopilot..."
    # Run the ArgoCD Autopilot bootstrap command
    argocd-autopilot repo bootstrap \
        --app "https://github.com/argoproj-labs/argocd-autopilot/manifests/insecure" \
        --recover \
        --git-token "$GIT_TOKEN" \
        --repo "$GIT_REPO"
    if [[ $? -eq 0 ]]; then
        echo "ArgoCD Autopilot setup completed successfully."
    else
        echo "ArgoCD Autopilot setup failed."
        exit 1
    fi
}
setup_git_repo(){
    local name="git-repo"
    
      # Create and render the Kubernetes secret manifest directly with EOF
    cat <<EOF > gitrepo-secret.yaml
apiVersion: v1
kind: Secret
metadata:
name: $name
namespace: argocd
labels:
    argocd.argoproj.io/secret-type: repository
stringData:
type: git
url: $GIT_REPO
EOF
    # Apply the secret
    kubectl apply -f gitrepo-secret.yaml
    rm -f gitrepo-secret.yaml

}
setup_argocd_admin_password(){

    if [[ -z $ARGOCD_PASSWORD ]]; then
        echo "ARGOCD_PASSWORD is not set. Exiting."
        exit 1
    fi
    echo "Changing the ArgoCD admin password..."
    # Get the ArgoCD admin password
    password=$(argocd account bcrypt --password $ARGOCD_PASSWORD)
    kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "'$password'",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
    # Restart the ArgoCD server pod
    kubectl -n argocd rollout restart deployment argocd-server

}

# Call the setup function with parsed arguments
setup_argocd_autopilot

setup_git_repo
setup_argocd_admin_password
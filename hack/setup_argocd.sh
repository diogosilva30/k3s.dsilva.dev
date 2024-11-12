#!/bin/bash
# Usage: ./hack/setup_argocd.sh -t $GIT_TOKEN -r $GIT_REPO -c $CLUSTER_NAME

# Function to setup ArgoCD Autopilot
setup_argocd_autopilot() {
    local git_token="$1"
    local git_repo="$2"
    local cluster_name="$3"

    export GIT_TOKEN="$git_token"
    export GIT_REPO="$git_repo"
    export CLUSTER_NAME="$cluster_name"
    # Run the ArgoCD Autopilot bootstrap command
    argocd-autopilot repo bootstrap \
        --app "https://github.com/argoproj-labs/argocd-autopilot/manifests/insecure" \
        --recover
    if [[ $? -eq 0 ]]; then
        echo "ArgoCD Autopilot setup completed successfully."
    else
        echo "ArgoCD Autopilot setup failed."
        exit 1
    fi
}

# Parse command line arguments
while getopts ":t:r:c:" opt; do
    case ${opt} in
        t) git_token="$OPTARG" ;;
        r) git_repo="$OPTARG" ;;
        c) cluster_name="$OPTARG" ;;
        \?) echo "Usage: $0 -t git_token -r git_repo -c cluster_name" >&2
            exit 1 ;;
    esac
done

# Validate required arguments
if [ -z "$git_token" ] || [ -z "$git_repo" ] || [ -z "$cluster_name" ]; then
    echo "Usage: $0 -t git_token -r git_repo -c cluster_name"
    exit 1
fi

# Call the setup function with parsed arguments
setup_argocd_autopilot "$git_token" "$git_repo" "$cluster_name"

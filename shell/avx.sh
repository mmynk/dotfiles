alias bootstrap="bazel run --config=sponge //go/aviatrix.com/cmd/avx_ctrl_bootstrap --"

kcloudx() {
  local pod_name
  pod_name=$(kubectl get pods --no-headers | awk '/^cloudxd/{print $1}' | head -n 1)

  if [ -z "$pod_name" ]; then
    echo "Error: No pod found matching 'cloudxd'."
    return 1
  fi

  echo "Executing into pod: $pod_name"
  kubectl exec -it "$pod_name" -- bash
}

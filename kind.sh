#!/usr/bin/env bash -e

PROJECT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
echo "Executing script in ${PROJECT_DIR}"
echo

# Run the functions as parameters to the script
# --------------------------------------------------
# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  "$@"
else
  available_functions=$(declare -F | awk '{print $NF}' | sort | egrep -v "^_")
  echo "error: '$1' is not a valid function name" >&2
  echo
  echo "Usage: $(basename $BASH_SOURCE) <function name> <parameters>"
  echo "---"
  echo "Available function names"
  echo "---"
  for f in ${available_functions}; do
    echo "  - ${f}"
  done
  exit 1
fi

function create_cluster() {
    kind create cluster --config=cluster.yaml
}

## Source: https://kind.sigs.k8s.io/docs/user/local-registry/
function create_registry() {
    reg_name='kind-registry'
    reg_port='5001'
    if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
        docker run \
            -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
            registry:2
    fi
}

function connect_registry() {
    reg_name='kind-registry'
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
        docker network connect "kind" "${reg_name}"
    fi
}

function local_registry_up() {
    create_registry
    connect_registry
}

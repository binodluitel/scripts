#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit ; pwd -P )
echo "Executing script in ${SCRIPT_DIR}"
echo

CLUSTER_NAME=test-cluster

function create_cluster() {
  kind create cluster --config="${SCRIPT_DIR}/kind.cluster.yaml"
}

function setup_registry() {
  local reg_name='kind-registry'
  local reg_port='5001'
  if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
    docker run -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" registry:2
  fi

  if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
    docker network connect "kind" "${reg_name}"
  fi
}

function setup() {
  create_cluster
  setup_registry
}

function clean() {
  kind delete cluster -n "${CLUSTER_NAME}"
  docker stop kind-registry
  docker rm -f kind-registry
}

# Run the functions as parameters to the script
# --------------------------------------------------
# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  "$@"
else
  available_functions=$(declare -F | awk '{print $NF}' | sort | grep -E -v "^_")
  echo "error: '$1' is not a valid function name" >&2
  echo
  echo "Usage: $(basename "${BASH_SOURCE[@]}") <function name> <parameters>"
  echo "---"
  echo "Available function names"
  echo "---"
  for f in ${available_functions}; do
    echo "  - ${f}"
  done
  exit 1
fi

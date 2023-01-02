#!/usr/bin/env bash -e

PROJECT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
echo "Executing script in ${PROJECT_DIR}"
echo

## Checkout GitHub PR locally
function git-pr() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Current directory is not a git repo ..." >&2; exit 1; }
  if [ -z "$1" ]; then
   echo "PR ID number is required ..."
   exit 1
  fi
  echo "Checking out PR $1"
  git checkout master
  git branch -D pr$1
  git fetch origin pull/$1/head:pr$1
  git checkout pr$1
}

# renew_dhcp_lease for mac only
function renew_dhcp_lease() {
    # If there are multiple files, remove them all
    # Example filename: ${HOME}/Library/VirtualBox/HostInterfaceNetworking-vboxnet0-Dhcpd.leases
    local vbox_lib_dir="${HOME}/Library/VirtualBox"

    kill -9 $(ps aux | grep -i "vboxsvc\|vboxnetdhcp" | awk '{print $2}') 2>/dev/null

    # remove all HostInterfaceNetworking-vboxnet* files
    find "${vbox_lib_dir}" -name 'HostInterfaceNetworking-vboxnet*' -delete
    echo "Done reseting Virtualbox DHCP lease"
}

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

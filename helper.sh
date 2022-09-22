#!/usr/bin/env bash -e

PROJECT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

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

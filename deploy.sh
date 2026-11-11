#!/usr/bin/env bash
# @license
# Copyright (c) rljson
#
# Use of this source code is governed by terms that can be
# found in the LICENSE file in the root of this package.

# Deploys one Bicep component into the resource group of an environment.
# Shows the what-if first and applies only after a yes.
#
# Usage: ./deploy.sh <component> <env> [--what-if]
#   --what-if  show the changes, apply nothing

set -euo pipefail
cd "$(dirname "$0")"
source lib/common.sh

component="${1:-}"
env="${2:-}"
mode="${3:-}"

[ -n "$component" ] || fail "Usage: ./deploy.sh <component> <env> [--what-if]"
require_env "$env"
case "$mode" in
  "" | --what-if) ;;
  *) fail "Unknown option '$mode'" ;;
esac

params="bicep/$component/$component-$env.bicepparam"
[ -f "bicep/$component/main.bicep" ] || fail "Missing bicep/$component/main.bicep"
[ -f "$params" ] || fail "Missing $params"

require_subscription
group="$(resource_group "$env")"
[ "$(az group exists --name "$group")" = "true" ] ||
  fail "$group is missing. Run: bootstrap/bootstrap.sh $env"

user="$(signed_in_user)"
extra=(--parameters techResponsibility="$user")

if [ "$mode" = "--what-if" ]; then
  az deployment group what-if \
    --resource-group "$group" \
    --parameters "$params" \
    "${extra[@]}"
  exit 0
fi

az deployment group create \
  --resource-group "$group" \
  --name "$component-$(date +%Y%m%d-%H%M%S)" \
  --parameters "$params" \
  "${extra[@]}" \
  --confirm-with-what-if

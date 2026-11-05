#!/usr/bin/env bash
# @license
# Copyright (c) rljson
#
# Use of this source code is governed by terms that can be
# found in the LICENSE file in the root of this package.

# Shared settings and checks of the scripts in this repo.

SUBSCRIPTION="cars"
LOCATION="germanywestcentral"
ENVIRONMENTS="demo"

# Entra groups that get cluster admin rights in AKS
CLUSTER_ADMIN_GROUPS="cars-admins cars-operators"

fail() {
  echo "❌ $*" >&2
  exit 1
}

# Exits unless the environment is one of ENVIRONMENTS.
require_env() {
  local env="$1"
  [ -n "$env" ] || fail "Name the environment: $ENVIRONMENTS"
  case " $ENVIRONMENTS " in
    *" $env "*) ;;
    *) fail "Unknown environment '$env'. Known: $ENVIRONMENTS" ;;
  esac
}

# Exits unless the Azure CLI is signed in and points at SUBSCRIPTION.
require_subscription() {
  local current
  current="$(az account show --query name -o tsv 2>/dev/null)" ||
    fail "Not signed in. Run: az login"
  [ "$current" = "$SUBSCRIPTION" ] ||
    fail "Active subscription is '$current'. Run: az account set --subscription $SUBSCRIPTION"
}

# Prints the user principal name of the signed-in user.
# Prints the object IDs of the named Entra groups as a JSON array
group_ids_json() {
  local json="" name id
  for name in "$@"; do
    id="$(az ad group show --group "$name" --query id -o tsv)" || fail "Entra group '$name' not found"
    json="$json${json:+,}\"$id\""
  done
  echo "[$json]"
}

signed_in_user() {
  az ad signed-in-user show --query userPrincipalName -o tsv
}

# Prints the resource group of an environment.
resource_group() {
  echo "rg-cars-$1"
}

#!/usr/bin/env bash
# @license
# Copyright (c) rljson
#
# Use of this source code is governed by terms that can be
# found in the LICENSE file in the root of this package.

# Shared settings and checks of the scripts in this repo.

SUBSCRIPTION="cars"
LOCATION="westeurope"
ENVIRONMENTS="demo"

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
signed_in_user() {
  az ad signed-in-user show --query userPrincipalName -o tsv
}

# Prints the resource group of an environment.
resource_group() {
  echo "rg-cars-$1"
}

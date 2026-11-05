#!/usr/bin/env bash
# @license
# Copyright (c) rljson
#
# Use of this source code is governed by terms that can be
# found in the LICENSE file in the root of this package.

# Creates the resource group of an environment. Run once per environment.
#
# Usage: bootstrap/bootstrap.sh <env>

set -euo pipefail
cd "$(dirname "$0")/.."
source lib/common.sh

env="${1:-}"
require_env "$env"
require_subscription

group="$(resource_group "$env")"

if [ "$(az group exists --name "$group")" = "true" ]; then
  echo "✅ $group exists already, nothing to do"
  exit 0
fi

az group create \
  --name "$group" \
  --location "$LOCATION" \
  --tags application=cars environment="$env" \
  techresponsibility="$(signed_in_user)" \
  --output table

echo "✅ Created $group in $LOCATION"

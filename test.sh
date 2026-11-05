#!/usr/bin/env bash
# @license
# Copyright (c) rljson
#
# Use of this source code is governed by terms that can be
# found in the LICENSE file in the root of this package.

# The test of cars-infra: builds every Bicep and parameter file.
# Run it before each commit.
#
#   ./test.sh

set -euo pipefail
cd "$(dirname "$0")"

failed=0
count=0
for file in $(find bicep -name '*.bicep' -o -name '*.bicepparam' | sort); do
  count=$((count + 1))
  case "$file" in
    *.bicepparam) cmd=(az bicep build-params --file "$file" --stdout) ;;
    *) cmd=(az bicep build --file "$file" --stdout) ;;
  esac
  if "${cmd[@]}" > /dev/null; then
    echo "✅ $file"
  else
    echo "❌ $file"
    failed=$((failed + 1))
  fi
done

[ "$count" -gt 0 ] || { echo "❌ No Bicep files found"; exit 1; }
[ "$failed" -eq 0 ] || { echo "❌ $failed of $count files failed"; exit 1; }
echo "✅ All $count files build"

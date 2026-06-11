#!/usr/bin/env bash
#
# Check for deprecated or removed Kubernetes APIs before an EKS upgrade.
#
# A new Kubernetes version removes APIs that older manifests still use.
# Catching those before the upgrade is the difference between a calm
# rollout and a broken workload. This uses FairwindsOps pluto to scan
# the live cluster and your local manifests.
#
# Usage:
#   ./scripts/check-deprecated-apis.sh <target-version>   e.g. 1.33
#
set -euo pipefail

TARGET_VERSION="${1:-}"
if [[ -z "${TARGET_VERSION}" ]]; then
  echo "Usage: $0 <target-kubernetes-version>   e.g. $0 1.33"
  exit 1
fi

if ! command -v pluto >/dev/null 2>&1; then
  echo "pluto not found. Install it from https://github.com/FairwindsOps/pluto"
  echo "  brew install FairwindsOps/tap/pluto    # macOS"
  exit 1
fi

echo "Scanning the live cluster for APIs removed in or before v${TARGET_VERSION}..."
pluto detect-all-in-cluster --target-versions "k8s=v${TARGET_VERSION}"

echo
echo "Scanning local manifests in ./manifests (if present)..."
if [[ -d "./manifests" ]]; then
  pluto detect-files -d ./manifests --target-versions "k8s=v${TARGET_VERSION}"
else
  echo "No ./manifests directory, skipping file scan."
fi

echo
echo "Done. Fix anything flagged above before bumping kubernetes_version."

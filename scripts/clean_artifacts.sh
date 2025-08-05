#!/bin/bash
# Usage: ./scripts/clean_artifacts.sh
# Cleans test and build artifacts.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

log_info "Cleaning test and build artifacts..."
rm -rf TestResults.xcresult build/reports sonar-reports ./scripts/build
log_success "Artifacts cleaned"

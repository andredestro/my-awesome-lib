#!/bin/bash
# Usage: ./scripts/run_swiftlint.sh <PROJECT_NAME>
# Runs SwiftLint analysis and outputs report.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ $# -ne 1 ]; then
  log_error "Usage: $0 <PROJECT_NAME>"
  exit 1
fi

PROJECT_NAME="$1"

log_info "Running SwiftLint analysis..."
mkdir -p sonar-reports
swiftlint --reporter checkstyle > "sonar-reports/$PROJECT_NAME-swiftlint.xml" || true
log_success "SwiftLint analysis completed"

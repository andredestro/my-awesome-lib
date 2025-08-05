#!/bin/bash
# Usage: ./scripts/extract_code_coverage.sh <COVERAGE_TARGET_FILTER> [XCRESULT_NAME]
# Extracts code coverage for the given target from the xcresult bundle.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  log_error "Usage: $0 <COVERAGE_TARGET_FILTER> [XCRESULT_NAME]"
  exit 1
fi

COVERAGE_TARGET_FILTER="$1"
XCRESULT_NAME="${2:-TestResults.xcresult}"

log_info "Extracting code coverage..."
if [ ! -d "$XCRESULT_NAME" ]; then
    log_warning "$XCRESULT_NAME not found."
    export COVERAGE_PERCENTAGE="N/A"
    exit 1
fi
coverage_percentage=$(xcrun xccov view --report "$XCRESULT_NAME" | grep "$COVERAGE_TARGET_FILTER" | head -1 | grep -o '[0-9]\+\.[0-9]\+%' | head -1)
if [ -n "$coverage_percentage" ]; then
    log_success "Code coverage ($COVERAGE_TARGET_FILTER): $coverage_percentage"
    export COVERAGE_PERCENTAGE="$coverage_percentage"
else
    log_warning "Could not extract coverage percentage for $COVERAGE_TARGET_FILTER"
    export COVERAGE_PERCENTAGE="N/A"
fi

# Only write to GITHUB_ENV if it is set (i.e., running in GitHub Actions)
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "COVERAGE_PERCENTAGE=$COVERAGE_PERCENTAGE" >> "$GITHUB_ENV"
fi

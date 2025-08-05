#!/bin/bash
# Usage: ./scripts/generate_coverage_report.sh <SCHEME_NAME> <XCODEPROJ_PATH> [XCRESULT_NAME]
# Generates code coverage report for SonarQube using Slather.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  log_error "Usage: $0 <SCHEME_NAME> <XCODEPROJ_PATH> [XCRESULT_NAME]"
  exit 1
fi

SCHEME_NAME="$1"
XCODEPROJ_PATH="$2"
XCRESULT_NAME="${3:-TestResults.xcresult}"

log_info "Generating code coverage report..."
if [ ! -d "$XCRESULT_NAME" ]; then
    log_warning "$XCRESULT_NAME not found."
    exit 1
fi
mkdir -p sonar-reports
if slather coverage --sonarqube-xml --output-directory sonar-reports --scheme "$SCHEME_NAME" "$XCODEPROJ_PATH"; then
    if [ -f "sonar-reports/sonarqube-generic-coverage.xml" ]; then
        log_success "Coverage converted successfully with Slather"
    else
        log_warning "Slather succeeded but output file not found"
    fi
else
    log_error "Slather failed to generate coverage report"
fi

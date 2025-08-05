#!/bin/bash
#!/bin/bash
# Usage: ./scripts/run_unit_tests.sh <XCODEPROJ_PATH> <SCHEME_NAME> <IOS_SIMULATOR_DEVICE> [REPORTS_DIR] [XCRESULT_NAME]
# Runs unit tests for the given Xcode project, scheme, and simulator device.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ $# -lt 3 ] || [ $# -gt 5 ]; then
  log_error "Usage: $0 <XCODEPROJ_PATH> <SCHEME_NAME> <IOS_SIMULATOR_DEVICE> [REPORTS_DIR] [XCRESULT_NAME]"
  exit 1
fi

XCODEPROJ_PATH="$1"
SCHEME_NAME="$2"
IOS_SIMULATOR_DEVICE="$3"
REPORTS_DIR="${4:-build/reports}"
XCRESULT_NAME="${5:-TestResults.xcresult}"

log_info "Running unit tests..."
mkdir -p "$REPORTS_DIR"
rm -rf "$XCRESULT_NAME" || true
xcodebuild test \
    -project "$XCODEPROJ_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE" \
    -configuration Debug \
    -enableCodeCoverage YES \
    -resultBundlePath "$XCRESULT_NAME" \
    SKIP_SCRIPT_PHASES=YES \
    CODE_SIGNING_ALLOWED=NO | xcbeautify --report junit --report-path "$REPORTS_DIR"
log_success "Unit tests completed"

# Only write to GITHUB_ENV if it is set (i.e., running in GitHub Actions)
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "IOS_SIMULATOR_DEVICE=$IOS_SIMULATOR_DEVICE" >> "$GITHUB_ENV"
fi

#!/bin/bash
# Usage: ./scripts/build_xcframework.sh <PROJECT_NAME> <SCHEME_NAME> <XCODEPROJ_PATH>
# Builds the XCFramework for the given project, scheme, and project path.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ $# -ne 3 ]; then
  log_error "Usage: $0 <PROJECT_NAME> <SCHEME_NAME> <XCODEPROJ_PATH>"
  exit 1
fi

PROJECT_NAME="$1"
SCHEME_NAME="$2"
XCODEPROJ_PATH="$3"

"$SCRIPT_DIR/install_dependencies.sh"
log_info "Building XCFramework..."
rm -rf build/*.xcarchive build/*.xcframework 2>/dev/null || true
xcodebuild archive \
    -scheme "$PROJECT_NAME" \
    -configuration Release \
    -destination 'generic/platform=iOS Simulator' \
    -archivePath "build/${PROJECT_NAME}.framework-iphonesimulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES | xcbeautify
xcodebuild archive \
    -scheme "$PROJECT_NAME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "build/${PROJECT_NAME}.framework-iphoneos.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES | xcbeautify
xcodebuild -create-xcframework \
    -framework "build/${PROJECT_NAME}.framework-iphonesimulator.xcarchive/Products/Library/Frameworks/${PROJECT_NAME}.framework" \
    -framework "build/${PROJECT_NAME}.framework-iphoneos.xcarchive/Products/Library/Frameworks/${PROJECT_NAME}.framework" \
    -output "build/${PROJECT_NAME}.xcframework"
log_success "XCFramework built successfully"

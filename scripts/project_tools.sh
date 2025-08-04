#!/bin/bash

# Project Automation Script for __PROJECT_NAME__
# Usage: ./scripts/project_tools.sh [command]
# Commands: build | test | lint | coverage | coverage-report | clean | install-deps | help

set -euo pipefail

# Default configuration (can be overridden by environment variables)
IOS_SIMULATOR_DEVICE="${IOS_SIMULATOR_DEVICE:-iPhone 16}"
PROJECT_NAME="${PROJECT_NAME:-__PROJECT_NAME__}"
SCHEME_NAME="${SCHEME_NAME:-__PROJECT_NAME__}"
XCODEPROJ_PATH="${XCODEPROJ_PATH:-__PROJECT_NAME__.xcodeproj}"
COVERAGE_TARGET_FILTER="${COVERAGE_TARGET_FILTER:-__PROJECT_NAME__}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

install_dependencies() {
    log_info "Installing dependencies..."

    # Install SwiftLint
    if ! command -v swiftlint &> /dev/null; then
        log_info "Installing SwiftLint..."
        brew install swiftlint
    else
        log_success "SwiftLint already installed"
    fi

    # Install xcbeautify for better output formatting
    if ! command -v xcbeautify &> /dev/null; then
        log_info "Installing xcbeautify..."
        brew install xcbeautify
    else
        log_success "xcbeautify already installed"
    fi

    # Install slather for coverage conversion
    if ! gem list slather -i &> /dev/null; then
        log_info "Installing slather..."
        gem install slather
    else
        log_success "slather already installed"
    fi

    log_success "All dependencies installed"
}

run_unit_tests() {
    log_info "Running unit tests..."
    mkdir -p build/reports
    rm -rf TestResults.xcresult || true
    xcodebuild test \
        -project "$XCODEPROJ_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE" \
        -configuration Debug \
        -enableCodeCoverage YES \
        -resultBundlePath TestResults.xcresult \
        SKIP_SCRIPT_PHASES=YES \
        CODE_SIGNING_ALLOWED=NO | xcbeautify --report junit --report-path build/reports
    log_success "Unit tests completed"
}

extract_code_coverage() {
    log_info "Extracting code coverage..."
    if [ ! -d "TestResults.xcresult" ]; then log_warning "TestResults.xcresult not found."; export COVERAGE_PERCENTAGE="N/A"; return 1; fi
    coverage_percentage=$(xcrun xccov view --report TestResults.xcresult | grep "$COVERAGE_TARGET_FILTER" | head -1 | grep -o '[0-9]\+\.[0-9]\+%' | head -1)
    if [ -n "$coverage_percentage" ]; then
        log_success "Code coverage ($COVERAGE_TARGET_FILTER): $coverage_percentage"
        export COVERAGE_PERCENTAGE="$coverage_percentage"
    else
        log_warning "Could not extract coverage percentage for $COVERAGE_TARGET_FILTER"
        export COVERAGE_PERCENTAGE="N/A"
    fi
}

generate_coverage_report() {
    log_info "Generating code coverage report..."
    if [ ! -d "TestResults.xcresult" ]; then log_warning "TestResults.xcresult not found."; return 1; fi
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
}

run_swiftlint() {
    log_info "Running SwiftLint analysis..."
    mkdir -p sonar-reports
    swiftlint --reporter checkstyle > "sonar-reports/$PROJECT_NAME-swiftlint.xml" || true
    log_success "SwiftLint analysis completed"
}

build_xcframework() {
    install_dependencies
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
}

clean_artifacts() {
    log_info "Cleaning test and build artifacts..."
    rm -rf TestResults.xcresult build/reports sonar-reports ./scripts/build
    log_success "Artifacts cleaned"
}

display_test_summary() {
    log_info "Test Summary:"
    echo "=================================="
    echo "Project: $PROJECT_NAME"
    echo "Scheme: $SCHEME_NAME"
    echo "Simulator: $IOS_SIMULATOR_DEVICE"
    echo "Coverage: ${COVERAGE_PERCENTAGE:-N/A}"
    echo "=================================="
    if [ -f "TestResults.xcresult" ]; then
        log_success "Test results available in: TestResults.xcresult"
    fi
    if [ -d "sonar-reports" ]; then
        log_success "Analysis reports available in: sonar-reports/"
    fi
    if [ -d "build/reports" ]; then
        log_success "JUnit reports available in: build/reports/"
    fi
}

run_full_test_suite() {
    log_info "Starting full test suite..."
    install_dependencies
    run_unit_tests
    extract_code_coverage || log_warning "Coverage extraction failed, continuing..."
    generate_coverage_report || log_warning "Coverage report generation failed, continuing..."
    run_swiftlint
    display_test_summary
    log_success "Full test suite completed!"
}

show_help() {
    echo "Usage: $0 [COMMAND]"
    echo "Commands:"
    echo "  build             Build XCFramework for distribution"
    echo "  test              Run unit tests only"
    echo "  lint              Run SwiftLint analysis"
    echo "  coverage          Extract code coverage from test results"
    echo "  coverage-report   Generate code coverage report for SonarQube"
    echo "  install-deps      Install required dependencies"
    echo "  clean             Clean test and build artifacts"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/project_tools.sh build"
    echo "  ./scripts/project_tools.sh test"
    echo "  ./scripts/project_tools.sh full"
}

main() {
    case "${1:-help}" in
        "build") build_xcframework ;;
        "test") run_unit_tests ;;
        "lint") run_swiftlint ;;
        "coverage") extract_code_coverage ;;
        "coverage-report") generate_coverage_report ;;
        "install-deps") install_dependencies ;;
        "clean") clean_artifacts ;;
        "full") run_full_test_suite ;;
        "help"|"-h"|"--help") show_help ;;
        *) log_error "Unknown command: $1"; show_help; exit 1 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

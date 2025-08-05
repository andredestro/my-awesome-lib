#!/bin/bash

# Project Automation Script for __PROJECT_NAME__
# Usage: ./scripts/project_tools.sh [command]
# Commands: build | test | lint | coverage | coverage-report | clean | install-deps | help

set -euo pipefail

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Default configuration (can be overridden by environment variables)
IOS_SIMULATOR_DEVICE="${IOS_SIMULATOR_DEVICE:-iPhone 16}"
PROJECT_NAME="${PROJECT_NAME:-__PROJECT_NAME__}"
SCHEME_NAME="${SCHEME_NAME:-__PROJECT_NAME__}"
XCODEPROJ_PATH="${XCODEPROJ_PATH:-__PROJECT_NAME__.xcodeproj}"
COVERAGE_TARGET_FILTER="${COVERAGE_TARGET_FILTER:-__PROJECT_NAME__}"

install_dependencies() {
    "$SCRIPT_DIR/install_dependencies.sh"
}

run_unit_tests() {
    "$SCRIPT_DIR/run_unit_tests.sh" "$XCODEPROJ_PATH" "$SCHEME_NAME" "$IOS_SIMULATOR_DEVICE"
}

extract_code_coverage() {
    "$SCRIPT_DIR/extract_code_coverage.sh" "$COVERAGE_TARGET_FILTER"
}

generate_coverage_report() {
    "$SCRIPT_DIR/generate_coverage_report.sh" "$SCHEME_NAME" "$XCODEPROJ_PATH"
}

run_swiftlint() {
    "$SCRIPT_DIR/run_swiftlint.sh" "$PROJECT_NAME"
}

build_xcframework() {
    "$SCRIPT_DIR/build_xcframework.sh" "$PROJECT_NAME" "$SCHEME_NAME" "$XCODEPROJ_PATH"
}

clean_artifacts() {
    "$SCRIPT_DIR/clean_artifacts.sh"
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
    echo "  full              Run full test suite with coverage and linting"
    echo "  version           Project versioning operations (bump|get)"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/project_tools.sh build"
    echo "  ./scripts/project_tools.sh test"
    echo "  ./scripts/project_tools.sh version bump minor"
    echo "  ./scripts/project_tools.sh version get"
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
        "version") shift; bash "$SCRIPT_DIR/version.sh" "$@" ;;
        "help"|"-h"|"--help") show_help ;;
        *) log_error "Unknown command: $1"; show_help; exit 1 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

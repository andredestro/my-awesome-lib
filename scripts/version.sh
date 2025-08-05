#!/bin/bash
# version.sh: Centralizes iOS project versioning operations
# Usage:
#   ./scripts/version.sh bump [patch|minor|major]
#   ./scripts/version.sh get
set -euo pipefail

# Load standardized logging functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PBXPROJ="__PROJECT_NAME__.xcodeproj/project.pbxproj"

case "$1" in
  bump)
    BUMP_TYPE="${2:-patch}"
    log_info "Extracting current MARKETING_VERSION..."
    current_version=$(grep -m1 'MARKETING_VERSION =' "$PBXPROJ" | sed -E 's/.*MARKETING_VERSION = ([0-9]+\.[0-9]+\.[0-9]+);/\1/')
    IFS='.' read -r major minor patch <<< "$current_version"
    log_info "Current version: $current_version"
    case "$BUMP_TYPE" in
      major)
        major=$((major+1)); minor=0; patch=0;;
      minor)
        minor=$((minor+1)); patch=0;;
      *)
        patch=$((patch+1));;
    esac
    new_version="$major.$minor.$patch"

    log_info "Updating MARKETING_VERSION to $new_version..."
    sed -i '' -E "s/MARKETING_VERSION = [0-9]+\.[0-9]+\.[0-9]+;/MARKETING_VERSION = $new_version;/g" "$PBXPROJ"
    log_info "Updating CURRENT_PROJECT_VERSION..."
    current_proj_version=$(grep -m1 'CURRENT_PROJECT_VERSION =' "$PBXPROJ" | sed -E 's/.*CURRENT_PROJECT_VERSION = ([0-9]+);/\1/')
    new_proj_version=$((current_proj_version+1))
    sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $new_proj_version;/g" "$PBXPROJ"
    log_info "Updating version in podspec to $new_version..."
    PODSPEC_FILE="__PROJECT_NAME__.podspec"
    if [ -f "$PODSPEC_FILE" ]; then
      sed -i '' -E "s/(s.version\s*=\s*")[0-9]+\.[0-9]+\.[0-9]+(\")/\1$new_version\2/" "$PODSPEC_FILE"
      log_success "Podspec version updated to $new_version"
    else
      log_warning "Podspec file not found: $PODSPEC_FILE"
    fi
    log_success "Bumped MARKETING_VERSION to $new_version, CURRENT_PROJECT_VERSION to $new_proj_version"

    # Update CHANGELOG.md
    TODAY=$(date +%Y-%m-%d)
    CHANGELOG="docs/CHANGELOG.md"
    log_info "Updating CHANGELOG.md for version $new_version..."
    awk -v ver="$new_version" -v today="$TODAY" '
      BEGIN { unreleased_found=0 }
      /^## \[Unreleased\]/ {
        print $0; print ""; print "## [" ver "] - " today; unreleased_found=1; next
      }
      { print $0 }
    ' "$CHANGELOG" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"
    log_success "CHANGELOG updated for version $new_version"
    ;;
  get)
    grep -m1 'MARKETING_VERSION =' "$PBXPROJ" | sed -E 's/.*MARKETING_VERSION = ([0-9]+\.[0-9]+\.[0-9]+);/\1/'
    ;;
  *)
    echo "Usage: $0 bump [patch|minor|major] | get"
    exit 1
    ;;
esac

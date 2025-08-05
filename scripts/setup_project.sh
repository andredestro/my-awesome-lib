#!/bin/bash

# OSLibraryTemplate-iOS Setup Script
# This script configures a new iOS library project from the template

set -e  # Exit on any error

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to validate project name
validate_project_name() {
    local name="$1"
    
    # Check if name is empty
    if [[ -z "$name" ]]; then
        log_error "Project name cannot be empty"
        return 1
    fi
    
    # Check if name contains only valid characters (letters, numbers, underscores)
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        log_error "Project name must start with a letter and contain only letters, numbers, and underscores"
        return 1
    fi
    
    return 0
}

# Function to validate bundle identifier
validate_bundle_identifier() {
    local bundle_id="$1"
    
    # Check if bundle identifier is empty
    if [[ -z "$bundle_id" ]]; then
        log_error "Bundle identifier cannot be empty"
        return 1
    fi
    
    # Check bundle identifier format (reverse domain notation)
    if [[ ! "$bundle_id" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*(\.[a-zA-Z0-9][a-zA-Z0-9-]*)+$ ]]; then
        log_error "Bundle identifier must be in reverse domain notation (e.g., com.company.app)"
        return 1
    fi
    
    return 0
}

# Function to replace content in files
replace_in_file() {
    local file="$1"
    local search="$2"
    local replace="$3"
    
    if [[ -f "$file" ]]; then
        # Use different approach for different OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|${search}|${replace}|g" "$file"
        else
            # Linux
            sed -i "s|${search}|${replace}|g" "$file"
        fi
        log_info "Updated content in: $file"
    fi
}

# Function to rename files and directories
rename_items() {
    local old_name="$1"
    local new_name="$2"
    local base_dir="$3"
    
    # Find and rename directories first (depth-first to avoid path issues)
    find "$base_dir" -depth -name "*${old_name}*" -type d | while read -r dir; do
        local new_dir="${dir//$old_name/$new_name}"
        if [[ "$dir" != "$new_dir" ]]; then
            mv "$dir" "$new_dir"
            log_info "Renamed directory: $(basename "$dir") → $(basename "$new_dir")"
        fi
    done
    
    # Find and rename files
    find "$base_dir" -name "*${old_name}*" -type f | while read -r file; do
        local new_file="${file//$old_name/$new_name}"
        if [[ "$file" != "$new_file" ]]; then
            mv "$file" "$new_file"
            log_info "Renamed file: $(basename "$file") → $(basename "$new_file")"
        fi
    done
}

# Main setup function
main() {
    echo ""
    echo "🚀 iOS Library Template Setup"
    echo "============================="
    echo ""
    
    # Get current directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    
    log_info "Project root: $PROJECT_ROOT"
    
    # Get project name
    while true; do
        echo ""
        echo -n "Enter the project name (e.g., MyAwesomeLibrary): "
        read -r PROJECT_NAME
        
        if validate_project_name "$PROJECT_NAME"; then
            break
        fi
        echo ""
    done
    
    # Get bundle identifier
    while true; do
        echo ""
        echo -n "Enter the bundle identifier (e.g., com.company.mylibrary): "
        read -r BUNDLE_IDENTIFIER
        
        if validate_bundle_identifier "$BUNDLE_IDENTIFIER"; then
            break
        fi
        echo ""
    done
    
    echo ""
    log_info "Project Name: $PROJECT_NAME"
    log_info "Bundle Identifier: $BUNDLE_IDENTIFIER"
    
    # Confirm setup
    echo ""
    echo -n "Proceed with setup? (y/N): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warning "Setup cancelled"
        exit 0
    fi
    
    echo ""
    log_info "Starting project setup..."
    
    # Step 1: Replace content in all files
    log_info "Step 1: Updating file contents..."
    
    # Find all files that might contain placeholders (excluding binary files and git)
    find "$PROJECT_ROOT" -type f \
        ! -path "*/.git/*" \
        ! -path "*/.DS_Store" \
        ! -path "*/build/*" \
        ! -path "*/DerivedData/*" \
        ! -name "*.png" \
        ! -name "*.jpg" \
        ! -name "*.jpeg" \
        ! -name "*.gif" \
        ! -name "*.icns" \
        ! -name "*.ico" \
        ! -name "setup_project.sh" | while read -r file; do
        
        # Check if file contains placeholders
        if grep -l "__PROJECT_NAME__\|--BUNDLE-IDENTIFIER--\|--PROJECT-NAME--" "$file" 2>/dev/null; then
            replace_in_file "$file" "__PROJECT_NAME__" "$PROJECT_NAME"
            replace_in_file "$file" "--PROJECT-NAME--" "$PROJECT_NAME"
            replace_in_file "$file" "--BUNDLE-IDENTIFIER--" "$BUNDLE_IDENTIFIER"
        fi
    done
    
    # Step 2: Rename files and directories
    log_info "Step 2: Renaming files and directories..."
    
    # Change to project root to avoid path issues
    cd "$PROJECT_ROOT"
    
    # Rename items containing __PROJECT_NAME__
    rename_items "__PROJECT_NAME__" "$PROJECT_NAME" "$PROJECT_ROOT"
    
    # Step 3: Update README.md to be a standard Xcode library README
    log_info "Step 3: Creating standard library README..."
    cat > "$PROJECT_ROOT/docs/README.md" <<'EOF'
# __PROJECT_NAME__

## Development

### Opening the Project

Open the Xcode project:

```bash
open __PROJECT_NAME__.xcodeproj
```

### Building and Running

Use Xcode to build and run the project as usual.

### Testing

Run the tests using the Xcode Test navigator or the shortcut (⌘U).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
EOF
    
    # Replace the placeholder with actual project name
    replace_in_file "$PROJECT_ROOT/docs/README.md" "__PROJECT_NAME__" "$PROJECT_NAME"

    # Step 4: Update podspec URLs with the remote repository URL, if available
    log_info "Step 4: Updating podspec URLs if remote repository is set..."

    GIT_REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [[ -n "$GIT_REMOTE_URL" ]]; then
        PODSPEC_FILE="$PROJECT_ROOT/${PROJECT_NAME}.podspec"
        if [[ -f "$PODSPEC_FILE" ]]; then
            # homepage: remove .git from the end if present
            HOMEPAGE_URL="${GIT_REMOTE_URL%.git}"
            replace_in_file "$PODSPEC_FILE" "https://github.com/OutSystems/${PROJECT_NAME}" "$HOMEPAGE_URL"
            replace_in_file "$PODSPEC_FILE" "https://github.com/OutSystems/${PROJECT_NAME}.git" "$GIT_REMOTE_URL"
        fi
    fi

    # Step 5: Clean up any remaining template artifacts
    log_info "Step 5: Cleaning up..."

    # Remove docs/assets directory if it exists
    if [[ -d "$PROJECT_ROOT/docs/assets" ]]; then
        rm -rf "$PROJECT_ROOT/docs/assets"
        log_info "Removed docs/assets directory"
    fi

    # Remove this setup script
    if [[ -f "$PROJECT_ROOT/scripts/setup_project.sh" ]]; then
        rm "$PROJECT_ROOT/scripts/setup_project.sh"
        log_info "Removed setup script"
    fi
    
    echo ""
    log_success "✅ Project setup completed successfully!"
    echo ""
    log_info "Your new iOS library project '$PROJECT_NAME' is ready!"
    log_info "Location: $PROJECT_ROOT"
    echo ""
    log_info "Next steps:"
    echo "  1. Open the Xcode project:"
    echo "     open ${PROJECT_NAME}.xcodeproj"
    echo "  2. Build and run your library using Xcode."
    echo "  3. Add your source files in the appropriate group/folder."
    echo "  4. Add tests in the ${PROJECT_NAME}Tests target."
    echo "  5. Update the documentation in docs/README.md."
    echo ""

    # Optional: Commit and push changes
    echo -n "Do you want to commit and push all changes to git now? (y/N): "
    read -r git_confirm
    if [[ "$git_confirm" =~ ^[Yy]$ ]]; then
        cd "$PROJECT_ROOT"
        git add .
        git commit -m "chore: initial project setup with template"
        git push
        log_success "Changes committed and pushed to remote repository."
    else
        log_info "You can commit and push your changes manually later."
    fi

    log_success "Happy coding! 🎉"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

#!/bin/bash

# Utility functions for Docker scripts
# This file provides common functions used across Docker scripts

# Function to extract project name from pyproject.toml
get_project_name() {
    local pyproject_file="$(dirname "$0")/../../pyproject.toml"
    
    if [ ! -f "$pyproject_file" ]; then
        echo "❌ Error: pyproject.toml not found at $pyproject_file" >&2
        return 1
    fi
    
    # Extract project name from pyproject.toml
    local project_name=$(grep '^name = ' "$pyproject_file" | sed 's/name = "\(.*\)"/\1/' | tr -d '"')
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Could not extract project name from pyproject.toml" >&2
        return 1
    fi
    
    echo "$project_name"
}

# Function to get project prefix for Docker resources
get_project_prefix() {
    get_project_name
}

# Function to validate project name
validate_project_name() {
    local project_name="$1"
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name is empty" >&2
        return 1
    fi
    
    # Check if project name contains only valid characters for Docker resources
    if ! echo "$project_name" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9_.-]*$'; then
        echo "❌ Error: Project name '$project_name' contains invalid characters for Docker resources" >&2
        return 1
    fi
    
    return 0
}

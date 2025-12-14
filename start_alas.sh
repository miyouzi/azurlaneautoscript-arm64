#!/bin/bash

# AzurLaneAutoScript deployment script
set -e  # Exit immediately if a command exits with non-zero status

echo "Starting AzurLaneAutoScript deployment..."

# Function to detect IP location
detect_country() {
    echo "Detecting current IP location..."
    COUNTRY=$(curl -s --connect-timeout 5 --max-time 10 https://ipapi.co/country_code/ || echo "Unknown")

    # Alternative IP detection method
    if [[ "$COUNTRY" == "Unknown" ]]; then
        COUNTRY=$(curl -s --connect-timeout 5 --max-time 10 https://ifconfig.io/country_code || echo "Unknown")
    fi

    echo "Detected country: $COUNTRY"
}

# Function to determine and copy appropriate configuration
copy_configuration() {
    echo "Determining appropriate configuration based on location..."
    
    # Use IP detection to determine configuration
    if [[ "$COUNTRY" == "CN" ]]; then
        echo "Using Chinese configuration for Mainland China..."
        if [[ -f "AzurLaneAutoScript/config/deploy.template-docker-cn.yaml" ]]; then
            cp AzurLaneAutoScript/config/deploy.template-docker-cn.yaml AzurLaneAutoScript/config/deploy.yaml
            echo "Successfully copied Chinese configuration template"
        else
            echo "Warning: Chinese configuration template not found, trying international template..."
            if [[ -f "AzurLaneAutoScript/config/deploy.template-docker.yaml" ]]; then
                cp AzurLaneAutoScript/config/deploy.template-docker.yaml AzurLaneAutoScript/config/deploy.yaml
                echo "Successfully copied international configuration template as fallback"
            else
                echo "Error: No configuration template found"
                exit 1
            fi
        fi
    else
        echo "Using international configuration..."
        if [[ -f "AzurLaneAutoScript/config/deploy.template-docker.yaml" ]]; then
            cp AzurLaneAutoScript/config/deploy.template-docker.yaml AzurLaneAutoScript/config/deploy.yaml
            echo "Successfully copied international configuration template"
        else
            echo "Warning: International configuration template not found, trying Chinese template..."
            if [[ -f "AzurLaneAutoScript/config/deploy.template-docker-cn.yaml" ]]; then
                cp AzurLaneAutoScript/config/deploy.template-docker-cn.yaml AzurLaneAutoScript/config/deploy.yaml
                echo "Successfully copied Chinese configuration template as fallback"
            else
                echo "Error: No configuration template found"
                exit 1
            fi
        fi
    fi
}

# Check for USE_GITHUB_REPO environment variable
if [[ "$USE_GITHUB_REPO" == "Y" || "$USE_GITHUB_REPO" == "y" ]]; then
    echo "USE_GITHUB_REPO environment variable set to '$USE_GITHUB_REPO', forcing GitHub repository"
    FORCE_GITHUB=true
else
    FORCE_GITHUB=false
fi

# Check for ALAS_REPO environment variable (custom repository)
if [[ -n "$ALAS_REPO" ]]; then
    echo "ALAS_REPO environment variable set, using custom repository: $ALAS_REPO"
    CUSTOM_REPO=true
else
    CUSTOM_REPO=false
fi

# Change to /app directory
echo "Changing to /app directory..."
mkdir -p /app
cd /app

# Check if AzurLaneAutoScript directory already exists
if [[ -f "AzurLaneAutoScript/gui.py" ]]; then
    echo "AzurLaneAutoScript repository already exists, skipping clone step..."
else
    echo "AzurLaneAutoScript repository not found, starting clone process..."

    # Always detect country for configuration purposes
    detect_country

    # Determine repository source
    if [[ "$CUSTOM_REPO" == true ]]; then
        echo "Using custom repository: $ALAS_REPO"
        REPO_SOURCE="custom"
    elif [[ "$FORCE_GITHUB" == true ]]; then
        echo "Using GitHub repository (forced by environment variable)..."
        REPO_SOURCE="github"
    else
        # Determine repository source based on location
        if [[ "$COUNTRY" == "CN" ]]; then
            echo "Detected Mainland China, using domestic mirror..."
            REPO_SOURCE="domestic"
        else
            echo "Using GitHub official repository..."
            REPO_SOURCE="github"
        fi
    fi

    # Execute clone based on determined source
    case "$REPO_SOURCE" in
        "custom")
            # Clone from custom repository
            if git clone "$ALAS_REPO"; then
                echo "Successfully cloned from custom repository"
            else
                echo "Error: Failed to clone from custom repository: $ALAS_REPO"
                exit 1
            fi
            ;;
        "domestic")
            # Clone from domestic mirror
            if git clone git://git.lyoko.io/AzurLaneAutoScript; then
                echo "Successfully cloned from domestic mirror"
            else
                echo "Error: Failed to clone from domestic mirror, trying alternative method..."
                # Alternative method: use HTTPS protocol
                if git clone https://git.lyoko.io/AzurLaneAutoScript; then
                    echo "Successfully cloned using HTTPS protocol"
                else
                    echo "Error: All domestic mirror clone methods failed"
                    exit 1
                fi
            fi
            ;;
        "github")
            # Clone from GitHub
            if git clone https://github.com/LmeSzinc/AzurLaneAutoScript; then
                echo "Successfully cloned from GitHub"
            else
                echo "Error: Failed to clone from GitHub"
                exit 1
            fi
            ;;
    esac
    
    # Copy configuration based on IP location (regardless of repository source)
    copy_configuration
fi

# Enter AzurLaneAutoScript directory and start GUI
echo "Entering AzurLaneAutoScript directory..."
cd /app/AzurLaneAutoScript

echo "Starting AzurLaneAutoScript GUI..."
python3 gui.py
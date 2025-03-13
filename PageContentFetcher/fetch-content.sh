#!/bin/bash

# Ensure script fails on error
set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default Docker image name
DOCKER_IMAGE="page-content-fetcher:latest"

# Check if the Docker image exists
if ! docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
    echo "Building Docker image..."
    cd "$SCRIPT_DIR"
    docker build -t "$DOCKER_IMAGE" .
fi

# Extract arguments
URL=""
SELECTOR=""
USE_JS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --url=*)
            URL="${1#*=}"
            shift
            ;;
        --selector=*)
            SELECTOR="${1#*=}"
            shift
            ;;
        --useJavaScript)
            USE_JS=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$URL" ] || [ -z "$SELECTOR" ]; then
    echo '{"error":"Missing required parameters. Usage: ./fetch-content.sh --url=URL --selector=SELECTOR [--useJavaScript]","date":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}'
    exit 1
fi

# Build the Docker run command
JS_FLAG=""
if [ "$USE_JS" = true ]; then
    JS_FLAG="--useJavaScript"
fi

# Run the Docker container
docker run --rm "$DOCKER_IMAGE" --url "$URL" --selector "$SELECTOR" $JS_FLAG

# Exit with the same status as the Docker command
exit $? 
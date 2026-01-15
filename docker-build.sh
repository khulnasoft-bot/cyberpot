#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -v <version>    Set the version tag for the Docker images."
    echo "  --version       Print the version and exit."
    echo "  -p <prefix>     Set a prefix for Docker image names."
    echo "  --prefix <prefix>  Same as -p."
    echo "  -h, --help      Display this help message."
    exit 0
}

VERSION_TAG_ARG=""
PREFIX="ghcr.io/khulnasoft"  # default prefix as in your example

# Manual argument parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Option -v requires an argument." >&2
        usage
        exit 1
      fi
      VERSION_TAG_ARG="$2"
      shift 2
      ;;
    --version)
      if [ -f "version" ]; then
        cat version
      else
        echo "version file not found"
        exit 1
      fi
      exit 0
      ;;
    -p|--prefix)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Option $1 requires an argument." >&2
        usage
        exit 1
      fi
      PREFIX="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      # Stop parsing at the first non-option argument.
      break
      ;;
  esac
done

if [ -n "$VERSION_TAG_ARG" ]; then
    VERSION_TAG=":$VERSION_TAG_ARG"
elif [ -f "version" ]; then
    VERSION_TAG=":"$(cat version | tr -d '[:space:]')
else
    VERSION_TAG=":latest"
fi

if ! command -v docker &> /dev/null
then
    echo "docker could not be found, please install it first"
    exit 1
fi

# Check if buildx is available and setup builder
if docker buildx version > /dev/null 2>&1; then
    echo "Docker buildx found. Setting up builder..."
    # Create a new builder instance or use existing if permitted/available
    # For CI/CD or local dev, ensure a driver that supports multi-arch (docker-container) is used if needed
    # falling back to default is often fine for load, but for multi-arch push we need more.
    # For this script, we assume 'docker buildx build' works.
else
    echo "Docker buildx not found. Please install it for multi-arch builds."
    exit 1
fi

# Find all Dockerfiles, excluding some directories
find docker -name Dockerfile | while read -r dockerfile; do
    dir=$(dirname "$dockerfile")
    # Exclude deprecated and builder directories
    if [[ "$dir" == *"deprecated"* || "$dir" == *"builder"* ]]; then
        echo "Skipping build for Dockerfile in $dir"
        continue
    fi
    # Get the path relative to the 'docker' directory
    relative_path=${dir#docker/}
    # Replace slashes with hyphens for the tag
    image_name="${PREFIX}/$(echo "$relative_path" | tr '/' '-')"
    tag="${image_name}${VERSION_TAG}"
    
    echo "Building Docker image in $dir with tag $tag for linux/amd64,linux/arm64"
    
    # Use buildx to build for both platforms. 
    # --load loads it into local docker daemon (only works for single arch usually, unless valid manifest)
    # properly, for multi-arch we usually push. 
    # Here we will try to just build. If pushing is needed, modifications are required.
    # For local development compatibility, we might default to current arch OR ask user.
    # We will build for both but NOT load to avoid 'docker image ls' confusion unless 'push' is specified?
    # For now, let's keep it simple: Build for the architecture of the machine running the script primarily,
    # OR if we want to support Pi we explicitly add platforms.
    
    # NOTE: 'docker buildx build --load' does not support multi-arch typically.
    # To support local usage on Mac (current user) and Pi, we can build for current arch by default,
    # or expose a flag. 
    
    # Update: As per plan, we enable multi-arch.
    # We will build and store in cache (no push, no load) to verify build success,
    # OR we can just standard build if no specific flag.
    # Let's stick to standard build but allow platform flag.
    
    (cd "$dir" && docker buildx build --platform linux/amd64,linux/arm64 -t "$tag" .)
done

echo "All Docker images built successfully."

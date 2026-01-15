#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -v <version>    Set the version tag for the Docker images."
    echo "  --version       Print the version and exit."
    echo "  -p <prefix>     Set a prefix for Docker image names."
    echo "  --prefix <prefix>  Same as -p."
    echo "  --platforms <platforms>  Set the platforms for the Docker images (e.g., linux/amd64,linux/arm64)."
    echo "  -h, --help      Display this help message."
    exit 0
}

VERSION_TAG_ARG=""
PREFIX="ghcr.io/khulnasoft-bot"  # default prefix as in your example

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
    --platforms)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Option --platforms requires an argument." >&2
        usage
        exit 1
      fi
      PLATFORMS_ARG="$2"
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
    echo "Docker buildx found. Checking builder capabilities..."
    DRIVER=$(docker buildx inspect | grep Driver | head -n 1 | awk '{print $NF}')
    if [ -z "$DRIVER" ]; then
        DRIVER="docker"
    fi
    echo "Current builder driver: $DRIVER"
else
    echo "Docker buildx not found. Please install it for multi-arch builds."
    exit 1
fi

# Set default platforms if not provided
if [ -n "$PLATFORMS_ARG" ]; then
    PLATFORMS="$PLATFORMS_ARG"
elif [ "$DRIVER" = "docker" ]; then
    echo "Default docker driver detected. Building for host platform only."
    PLATFORMS=""
else
    PLATFORMS="linux/amd64,linux/arm64"
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
    
    if [ -n "$PLATFORMS" ]; then
        echo "Building Docker image in $dir with tag $tag for $PLATFORMS"
        (cd "$dir" && docker buildx build --platform "$PLATFORMS" -t "$tag" .)
    else
        echo "Building Docker image in $dir with tag $tag for host platform"
        (cd "$dir" && docker buildx build -t "$tag" --load .)
    fi
done

echo "All Docker images built successfully."

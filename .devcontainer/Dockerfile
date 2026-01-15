# Stage 1: Build dependencies for Python and Node.js
FROM python:3.12-slim-bookworm AS builder

# Set build arguments
ARG DEBIAN_FRONTEND=noninteractive

# Install essential build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libcap2-bin \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y node-js \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Final development image
FROM python:3.12-slim-bookworm

LABEL maintainer="KhulnaSoft" \
    org.opencontainers.image.description="Optimized development container for CyberPot"

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    CYBERPOT_RESOURCE_MODE=LOW

# Install runtime dependencies and CLI tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    iproute2 \
    procps \
    sudo \
    vim-tiny \
    wget \
    docker.io \
    debootstrap \
    xorriso \
    squashfs-tools \
    isolinux \
    syslinux-common \
    psmisc \
    && rm -rf /var/lib/apt/lists/*

# Copy Node.js from builder (simpler to just install in final but builder shows multi-stage intent)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=cybernode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Add user to docker group (id 999 is common in many distros, but we should match host)
# Usually we handle this in devcontainer.json via remoteUser and group mounting
RUN groupadd -g 999 docker_host || true \
    && usermod -aG sudo $USERNAME

# Set up Workspace
WORKDIR /workspaces/cyberpot

# Harden container: setcap for raw socket access if needed by some sensors
# (though sensors run in their own containers, dev tools might need it)
RUN setcap cap_net_raw,cap_net_admin+p /usr/bin/python3.12

USER $USERNAME

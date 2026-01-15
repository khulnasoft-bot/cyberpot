#!/bin/bash
set -e

echo "🚀 Starting CyberPot Dev Setup..."

# Install backend dependencies
echo "📦 Installing Backend Dependencies..."
cd src/backend && npm install

# Install dashboard dependencies
echo "📦 Installing Dashboard Dependencies..."
cd ../dashboard && npm install

# Return to root
cd ../..

# Setup .env if it doesn't exist
if [ ! -f .env ]; then
    echo "📄 Creating default .env from example..."
    cp env.example .env
fi

# Optimization: Prune unused images and containers to save disk space
echo "🧹 Cleaning up Docker environment..."
docker system prune -f --volumes

echo "✅ Dev environment ready! Use 'docker-compose -f docker-compose.yml -f .devcontainer/docker-compose.dev.yml up -d' to start optimized services."

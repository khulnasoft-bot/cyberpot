# CyberPot Makefile
# This file provides shortcuts for common development and deployment tasks.

# Variables
VERSION   ?= $(shell cat version 2>/dev/null || echo "latest")
PREFIX    ?= ghcr.io/khulnasoft-bot
PLATFORMS ?= linux/amd64,linux/arm64
REGISTRY  ?= ghcr.io

COMPOSE_CORE       = docker-compose.yml
COMPOSE_MONITORING = docker-compose.monitoring.yml
COMPOSE_SCALE      = docker-compose.scale.yml

# Colors for help message
CYAN  := \033[36m
GREEN := \033[32m
RESET := \033[0m

.PHONY: all help build-images deploy install uninstall update genuser up down clean iso-build \
	up-monitoring down-monitoring up-scale down-scale lint-yaml lint-md test setup \
	dashboard-ui dashboard-api dashboard-all

# Default target
all: help

help: ## Show this help message
	@echo "$(GREEN)CyberPot Management Console$(RESET)"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'

setup: ## Initialize environment from example
	@if [ ! -f .env ]; then \
		cp env.example .env; \
		echo "$(GREEN).env file created from env.example$(RESET)"; \
	else \
		echo ".env already exists"; \
	fi

build-images: ## Build all Docker images using docker-build.sh
	@echo "Building all Docker images (Version: $(VERSION), Prefix: $(PREFIX))..."
	./docker-build.sh -v $(VERSION) -p $(PREFIX) --platforms $(PLATFORMS)

deploy: ## Run the deployment script
	@echo "Deploying Cyberpot services..."
	./deploy.sh

install: ## Run the installation script
	@echo "Installing Cyberpot..."
	./install.sh

uninstall: ## Run the uninstallation script
	@echo "Uninstalling Cyberpot..."
	./uninstall.sh

update: ## Run the update script
	@echo "Updating Cyberpot..."
	./update.sh

genuser: ## Run the user generation script
	@echo "Generating user..."
	./genuser.sh

up: ## Start core services
	@echo "Starting core services..."
	docker-compose -f $(COMPOSE_CORE) up -d

down: ## Stop core services
	@echo "Stopping core services..."
	docker-compose -f $(COMPOSE_CORE) down

up-monitoring: ## Start core services + monitoring stack (Prometheus, Grafana)
	@echo "Starting monitoring stack..."
	docker-compose -f $(COMPOSE_CORE) -f $(COMPOSE_MONITORING) up -d

down-monitoring: ## Stop monitoring stack
	@echo "Stopping monitoring stack..."
	docker-compose -f $(COMPOSE_CORE) -f $(COMPOSE_MONITORING) down

up-scale: ## Start core services + scaling configuration
	@echo "Starting scaled environment..."
	docker-compose -f $(COMPOSE_CORE) -f $(COMPOSE_SCALE) up -d

down-scale: ## Stop scaled environment
	@echo "Stopping scaled environment..."
	docker-compose -f $(COMPOSE_CORE) -f $(COMPOSE_SCALE) down

clean: ## Stop all services and prune Docker system (volumes included)
	@echo "Cleaning up Docker system..."
	docker-compose down --remove-orphans || true
	docker system prune -f --volumes

iso-build: ## Build the ISO image
	@echo "Building ISO image..."
	./iso-build/build.sh

lint-yaml: ## Lint YAML files using yamllint
	@echo "Linting YAML files..."
	yamllint .

lint-md: ## Lint Markdown files using markdownlint
	@echo "Linting Markdown files..."
	markdownlint .

test: ## Run performance/load tests (requires k6)
	@echo "Running performance tests..."
	@if command -v k6 > /dev/null; then \
		k6 run tests/performance/load-test.js; \
	else \
		echo "k6 not found. Please install it to run performance tests."; \
		exit 1; \
	fi

dashboard-ui: ## Run Dashboard UI in development mode
	@echo "Starting Dashboard UI..."
	cd src/dashboard && npm run dev

dashboard-api: ## Run Dashboard API in development mode
	@echo "Starting Dashboard API..."
	cd src/backend && npm start

dashboard-all: ## Run full Dashboard development environment (UI + API)
	@echo "Starting full Dashboard development environment..."
	@echo "Press Ctrl+C to stop both."
	@trap 'kill 0' SIGINT; \
	(cd src/backend && npm start) & \
	(cd src/dashboard && npm run dev) & \
	wait

.PHONY: all build-images deploy install uninstall update genuser up down clean iso-build

all: build-images

build-images:
	@echo "Building all Docker images..."
	./docker-build.sh

deploy:
	@echo "Deploying Cyberpot services..."
	./deploy.sh

install:
	@echo "Installing Cyberpot..."
	./install.sh

uninstall:
	@echo "Uninstalling Cyberpot..."
	./uninstall.sh

update:
	@echo "Updating Cyberpot..."
	./update.sh

genuser:
	@echo "Generating user..."
	./genuser.sh

up:
	@echo "Starting Docker Compose services..."
	docker-compose -f docker-compose.yml up -d

down:
	@echo "Stopping Docker Compose services..."
	docker-compose -f docker-compose.yml down

clean: down
	@echo "Cleaning up Docker system..."
	docker system prune -f --volumes

iso-build:
	@echo "Building ISO image..."
	./iso-build/build.sh

dashboard-ui:
	@echo "Starting Dashboard UI..."
	cd src/dashboard && npm run dev

dashboard-api:
	@echo "Starting Dashboard API..."
	cd src/backend && npm start

dashboard-all:
	@echo "Starting full Dashboard development environment..."
	# This requires multiple terminals or background processes
	(cd src/backend && npm start) & (cd src/dashboard && npm run dev)

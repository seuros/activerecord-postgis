# Makefile for Docker Compose

# Set the default docker-compose file
DOCKER_COMPOSE_FILE = docker-compose.yml

# Default service (optional)
SERVICE = activerecord-postgis

# Phony targets are those that do not represent actual files
.PHONY: up down start stop restart logs build

# Bring up the Docker services
up:
	@docker compose -f $(DOCKER_COMPOSE_FILE) up -d

# Bring down the Docker services
down:
	@docker compose -f $(DOCKER_COMPOSE_FILE) down

# Start the Docker services
start:
	@docker compose -f $(DOCKER_COMPOSE_FILE) start $(SERVICE)

# Stop the Docker services
stop:
	@docker compose -f $(DOCKER_COMPOSE_FILE) stop $(SERVICE)

# Restart the Docker services
restart:
	@docker compose -f $(DOCKER_COMPOSE_FILE) restart $(SERVICE)

# Show logs for the Docker services
logs:
	@docker compose -f $(DOCKER_COMPOSE_FILE) logs -f $(SERVICE)

# Build or rebuild services
build:
	@docker compose -f $(DOCKER_COMPOSE_FILE) build $(SERVICE)

# List out the targets
help:
	@echo "Makefile to manage Docker Compose"
	@echo ""
	@echo "Usage:"
	@echo "  make up          - Bring up the Docker services"
	@echo "  make down        - Bring down the Docker services"
	@echo "  make start       - Start the Docker services"
	@echo "  make stop        - Stop the Docker services"
	@echo "  make restart     - Restart the Docker services"
	@echo "  make logs        - Show logs for the Docker services"
	@echo "  make build       - Build or rebuild services"
	@echo "  make help        - Show this help message"
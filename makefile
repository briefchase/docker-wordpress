# USAGE:

# Run in development mode
go: setup run-mounted

# Stop all containers and clean up
stop: setup docker-clean

# Run in production mode
live: run-headless nuke-this

# Variables
DOCKER_COMPOSE_VERSION := 2.20.3
DOCKER_COMPOSE_PATH := /usr/local/bin/docker-compose
MYSQL_ROOT_PASSWORD := heythereroot
MYSQL_USER := mysqluser
MYSQL_PASSWORD := heythere
EXTERNAL_DOMAIN := 35.202.82.182
EMAIL := chaseglong@gmail.com

# SETUP
setup: install-docker restart-docker install-docker-compose verify-docker \
       download-nginx-config create-env-file modify-nginx-config \
       modify-certbot-service

# === DOCKER TARGETS ===
run-mounted: # Start containers with mounts for development
	@sudo docker-compose up

run-headless: # Start containers in detached mode
	@sudo docker-compose up -d

install-docker: # Install Docker
	@echo "Checking for Docker installation..."
	@if [ -x "$$(command -v docker)" ]; then \
		echo "Docker is already installed"; \
	else \
		if [ ! -f "./get-docker.sh" ]; then \
			echo "Downloading get-docker.sh..."; \
			curl -fsSL https://get.docker.com -o get-docker.sh; \
		fi; \
		echo "Making get-docker.sh executable..."; \
		chmod +x get-docker.sh; \
		echo "Running get-docker.sh..."; \
		sudo ./get-docker.sh; \
	fi

install-docker-compose: # Install or upgrade Docker Compose
	@echo "Installing/upgrading Docker Compose to version $(DOCKER_COMPOSE_VERSION)..."
	@sudo curl -L "https://github.com/docker/compose/releases/download/v$(DOCKER_COMPOSE_VERSION)/docker-compose-$$(uname -s)-$$(uname -m)" -o $(DOCKER_COMPOSE_PATH)
	@sudo chmod +x $(DOCKER_COMPOSE_PATH)
	@echo "Docker Compose installed/upgraded."

verify-docker: # Verify Docker and Docker Compose installations
	@docker --version
	@docker-compose --version

restart-docker: # Restart Docker service
	@sudo systemctl restart docker
	@echo "Docker service restarted."

docker-clean: # Stop and remove all containers, images, and networks
	@echo "Stopping all Docker containers..."
	@sudo docker stop $$(sudo docker ps -aq)
	@echo "Removing all Docker containers..."
	@sudo docker rm $$(sudo docker ps -aq)
	@echo "Removing all Docker images..."
	@sudo docker rmi $$(sudo docker images -q)
	@echo "Removing all Docker networks (except default ones)..."
	@sudo docker network prune -f
	@echo "Docker environment cleaned up. Volumes preserved."

docker-nuke: # Remove all unused Docker data
	@echo "Stopping all Docker containers..."
	@sudo docker stop $$(sudo docker ps -aq)
	@sudo docker system prune -a -f --volumes
	@echo "Docker system pruned."

# === TEMPLATING ===
download-nginx-config: # Download NGINX SSL configuration
	@sudo curl -sSLo ./nginx-conf/options-ssl-nginx.conf https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
	@echo "NGINX SSL configuration downloaded."

create-env-file: # Create .env file with MySQL configuration
	@echo "Creating .env file with MySQL configuration..."
	@sudo sh -c 'echo "MYSQL_ROOT_PASSWORD=$(MYSQL_ROOT_PASSWORD)" > .env'
	@sudo sh -c 'echo "MYSQL_USER=$(MYSQL_USER)" >> .env'
	@sudo sh -c 'echo "MYSQL_PASSWORD=$(MYSQL_PASSWORD)" >> .env'
	@echo ".env file created with database credentials."

modify-nginx-config: # Modify NGINX configuration to include external domains
	@echo "Modifying NGINX configuration to include external domains..."
	@sudo sed -i 's/\[EXTERNAL_DOMAIN\]/$(EXTERNAL_DOMAIN)/g' ./nginx-conf/nginx.conf
	@echo "NGINX configuration modified."

modify-certbot-service: # Update Certbot configuration in docker-compose.yml
	@echo "Updating Certbot configuration..."
	@sudo sed -i 's/\[EMAIL\]/$(EMAIL)/g' ./docker-compose.yml
	@sudo sed -i 's/\[EXTERNAL_DOMAIN\]/$(EXTERNAL_DOMAIN)/g' ./docker-compose.yml
	@echo "Certbot configuration updated."

# === CLEANUP ===
nuke-this: # destroy the pwd and everything inside of it including this file
	@sudo rm -rf pwd

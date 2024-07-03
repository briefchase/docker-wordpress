.PHONY: all check-docker install-docker stop-containers nuke-docker restart-docker install-docker-compose verify-installation download-nginx-config stop-and-clean create-env-file modify-nginx-config modify-certbot-service

# Setup tasks
setup: check-docker install-docker stop-containers nuke-docker restart-docker install-docker-compose verify-installation download-nginx-config create-env-file modify-nginx-config modify-certbot-service

# Stop all containers and clean up
stop: stop-and-clean

# Run in development mode
go: run-mounted

# Run in production mode
live: run-headless destroy-clone

# Variables
DOCKER_COMPOSE_VERSION := 2.20.3
DOCKER_COMPOSE_PATH := /usr/local/bin/docker-compose
MYSQL_ROOT_PASSWORD := heythereroot
MYSQL_USER := mysqluser
MYSQL_PASSWORD := heythere
EXTERNAL_DOMAIN := adhesiveaesthetics.com
CERTIFICATE_DOMAIN_FOLDER := adhesiveaesthetics-com
EMAIL := chaseglong@gmail.com

# Start containers with mounts for development
run-mounted:
	@sudo docker-compose up

# Start containers in detached mode
run-headless:
	@sudo docker-compose up -d

# Example of a target to clean up a directory
destroy-clone:
	@sudo rm -rf /path/to/previous/file

# Check if Docker is installed and install if not
check-docker:
	@command -v docker > /dev/null || (echo "Docker is not installed, installing now..." && make install-docker)

# Install Docker
install_docker:
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


# Stop all running containers
stop-containers:
	@CONTAINERS_RUNNING=$$(sudo docker ps -aq); \
	if [ -n "$$CONTAINERS_RUNNING" ]; then \
		sudo docker stop $$CONTAINERS_RUNNING; \
	else \
		echo "No containers to stop."; \
	fi

# Stop and remove all containers, images, and networks
stop-and-clean:
	@echo "Stopping all Docker containers..."
	@sudo docker stop $$(sudo docker ps -aq)
	@echo "Removing all Docker containers..."
	@sudo docker rm $$(sudo docker ps -aq)
	@echo "Removing all Docker images..."
	@sudo docker rmi $$(sudo docker images -q)
	@echo "Removing all Docker networks (except default ones)..."
	@sudo docker network prune -f
	@echo "Docker environment cleaned up. Volumes preserved."

# Remove all unused Docker data
nuke-docker:
	@sudo docker system prune -a -f --volumes
	@echo "Docker system pruned."

# Restart Docker service
restart-docker:
	@sudo systemctl restart docker
	@echo "Docker service restarted."

# Install or upgrade Docker Compose
install-docker-compose:
	@echo "Installing/upgrading Docker Compose to version $(DOCKER_COMPOSE_VERSION)..."
	@sudo curl -L "https://github.com/docker/compose/releases/download/v$(DOCKER_COMPOSE_VERSION)/docker-compose-$$(uname -s)-$$(uname -m)" -o $(DOCKER_COMPOSE_PATH)
	@sudo chmod +x $(DOCKER_COMPOSE_PATH)
	@echo "Docker Compose installed/upgraded."

# Verify Docker and Docker Compose installations
verify-installation:
	@docker --version
	@docker-compose --version

# Download NGINX SSL configuration
download-nginx-config:
	@sudo curl -sSLo ./nginx-conf/options-ssl-nginx.conf https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
	@echo "NGINX SSL configuration downloaded."

# Create .env file with MySQL configuration
create-env-file:
	@echo "Creating .env file with MySQL configuration..."
	@sudo sh -c 'echo "MYSQL_ROOT_PASSWORD=$(MYSQL_ROOT_PASSWORD)" > .env'
	@sudo sh -c 'echo "MYSQL_USER=$(MYSQL_USER)" >> .env'
	@sudo sh -c 'echo "MYSQL_PASSWORD=$(MYSQL_PASSWORD)" >> .env'
	@echo ".env file created with database credentials."

# Modify NGINX configuration to include external domains
modify-nginx-config:
	@echo "Modifying NGINX configuration to include external domains..."
	@sudo sed -i 's/\[EXTERNAL_DOMAIN\]/$(EXTERNAL_DOMAIN)/g' ./nginx-conf/nginx.conf
	@sudo sed -i 's/\[CERTIFICATE_DOMAIN_FOLDER\]/$(CERTIFICATE_DOMAIN_FOLDER)/g' ./nginx-conf/nginx.conf
	@echo "NGINX configuration modified."

# Update Certbot configuration in docker-compose.yml
modify-certbot-service:
	@echo "Updating Certbot configuration..."
	@sudo sed -i 's/\[EMAIL\]/$(EMAIL)/g' ./docker-compose.yml
	@sudo sed -i 's/\[EXTERNAL_DOMAIN\]/$(EXTERNAL_DOMAIN)/g' ./docker-compose.yml
	@echo "Certbot configuration updated."

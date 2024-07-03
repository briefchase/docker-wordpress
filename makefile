.PHONY: all check-docker install-docker stop-containers nuke-docker restart-docker install-docker-compose verify-installation download-nginx-config stop-and-clean

# Install
setup: check-docker install-docker stop-containers nuke-docker restart-docker install-docker-compose verify-installation download-nginx-config

# Stop
stop: stop-and-clean

# Run (Debug)
go: run-mounted

# Run (Production)
live: run-headless destroy-clone

# Variables
DOCKER_COMPOSE_VERSION := 2.20.3
DOCKER_COMPOSE_PATH := /usr/local/bin/docker-compose
MYSQL_ROOT_PASSWORD := heythereroot
MYSQL_USER := mysqluser
MYSQL_PASSWORD := heythere
EXTERNAL_DOMAIN := adhesiveaesthetics.com
EMAIL := chaseglong@gmail.com


 # target to modify nginx.conf to include the EXTERNAL_DOMAIN
 # target to Modify the certbot service definition to include EMAIL and EXTERNAL_DOMAIN


run-mounted:
	@sudo docker-compose up

run-headless:
	@sudo docker-compose up -d

destroy-clone:
# idk but destroy this repo
	@sudo

check-docker:
	@command -v docker > /dev/null || (echo "Docker is not installed, installing now..." && make install-docker)

install-docker:
	@curl -fsSL https://get.docker.com -o get-docker.sh
	@sudo sh get-docker.sh
	@rm get-docker.sh
	@echo "Docker installed."

stop-containers:
	@CONTAINERS_RUNNING=$$(sudo docker ps -aq); \
	if [ ! -z "$$CONTAINERS_RUNNING" ]; then \
		sudo docker stop $$CONTAINERS_RUNNING; \
	else \
		echo "No containers to stop."; \
	fi

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

nuke-docker:
	@sudo docker system prune -a -f --volumes
	@echo "Docker system pruned."

restart-docker:
	@sudo systemctl restart docker
	@echo "Docker service restarted."

install-docker-compose:
	@echo "Installing/upgrading Docker Compose to version $(DOCKER_COMPOSE_VERSION)..."
	@sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$$(uname -s)-$$(uname -m)" -o $(DOCKER_COMPOSE_PATH)
	@sudo chmod +x $(DOCKER_COMPOSE_PATH)
	@echo "Docker Compose installed/upgraded."

verify-installation:
	@docker --version
	@docker-compose --version

download-nginx-config:
	@sudo curl -sSLo /etc/nginx/conf.d/options-ssl-nginx.conf https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
	@echo "NGINX SSL configuration downloaded."

create-env-file:
	@echo "Creating .env file with MySQL configuration..."
	@echo "MYSQL_ROOT_PASSWORD=$(MYSQL_ROOT_PASSWORD)" > .env
	@echo "MYSQL_USER=$(MYSQL_USER)" >> .env
	@echo "MYSQL_PASSWORD=$(MYSQL_PASSWORD)" >> .env
	@echo ".env file created with database credentials."

modify-nginx-config:
	@echo "Modifying NGINX configuration to include external domains..."
	@sudo sed -i 's/\[EXTERNAL_DOMAIN\]/$(EXTERNAL_DOMAIN)/g' /etc/nginx/nginx.conf
	@echo "NGINX configuration modified."

update-certbot-config:
	@echo "Updating Certbot configuration..."
	@sudo sed -i 's/\[EMAIL\]/$(EMAIL)/g' /etc/letsencrypt/cli.ini
	@sudo sed -i 's/\[EXTERNAL_DOMAIN\]/$(EXTERNAL_DOMAIN)/g' /etc/letsencrypt/cli.ini
	@echo "Certbot configuration updated."
#!/bin/bash

# Constants
DOCKER_COMPOSE_VERSION='3'

# Assert Docker Installation
if command -v docker &>/dev/null; then
  echo "Docker installed"
else
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
fi

# Stop Running Containers
CONTAINERS_RUNNING=$(sudo docker ps -aq)
if [ ! -z "$CONTAINERS_RUNNING" ]; then
  sudo docker stop $CONTAINERS_RUNNING
else
  echo "No containers to stop"
fi

# Prune Docker System without removing volumes
sudo docker system prune -a -f

# Restart Docker
sudo systemctl restart docker

# Install Docker Compose
echo "Installing Docker Compose version $DOCKER_COMPOSE_VERSION..."
sudo curl -SL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Build and Up Docker Compose
sudo docker-compose -f docker-compose.yml build
sudo docker-compose -f docker-compose.yml up -d

echo "Docker Compose has been started."

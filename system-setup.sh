#!/bin/bash

# Constants
DOCKER_COMPOSE_VERSION='2.20.3'  # Docker Compose software version supporting Compose file format v3

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Git
echo "Installing Git..."
sudo apt-get install git -y

# Assert Docker installation
if command -v docker &>/dev/null; then
  echo "Docker is already installed."
else
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
fi

# Stop running containers
CONTAINERS_RUNNING=$(sudo docker ps -aq)
if [ ! -z "$CONTAINERS_RUNNING" ]; then
  sudo docker stop $CONTAINERS_RUNNING
else
  echo "No containers to stop."
fi

# Prune Docker system without removing volumes
sudo docker system prune -a -f

# Restart Docker service
sudo systemctl restart docker

# Install or upgrade Docker Compose
echo "Installing/upgrading Docker Compose to version $DOCKER_COMPOSE_VERSION..."
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m`" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
echo "Verifying installations..."
docker --version
docker-compose --version
git --version

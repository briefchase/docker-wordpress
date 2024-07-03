#!/bin/bash

# Check if the current directory is docker-wordpress
if [[ $(basename "$PWD") != "docker-wordpress" ]]; then
  echo "Error: This script must be run from inside the 'docker-wordpress' directory."
  exit 1
fi

# Run docker-compose up in detached mode
sudo docker-compose up -d

# Warning: The next command will delete the directory and all its contents irreversibly
# Ensure that this script is always run from the correct location and that deleting these files is safe
cd ..  # Move up a directory to safely remove the target directory
sudo rm -rf ./docker-wordpress

# Output completion message
echo "Docker containers started & repo deleted successfully."

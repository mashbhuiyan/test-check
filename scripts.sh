#!/bin/bash

# Check if nvm is installed, if not, install it
if [ ! -d "$HOME/.nvm" ]; then
  echo "nvm is not installed. Installing..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  source ~/.bashrc  # Make nvm available in the current session
fi

# Install the desired Node.js version (17.9.1)
echo "Installing Node.js version 17.9.1..."
nvm install 17.9.1

# Set the installed version as the default
nvm use 17.9.1
nvm alias default 17.9.1

# Verify the installation
node -v

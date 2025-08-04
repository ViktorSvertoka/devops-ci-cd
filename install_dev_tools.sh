#!/bin/bash

echo "🔧 Starting DevOps tools installation..."

# Update system and install base utilities
echo "🔄 Updating package list..."
sudo apt update -y
sudo apt install -y software-properties-common curl

# Install Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker is already installed."
else
    echo "🐳 Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "✅ Docker installed successfully."
fi

# Install Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose is already installed."
else
    echo "🔧 Installing Docker Compose..."
    sudo apt install -y docker-compose
    echo "✅ Docker Compose installed successfully."
fi

# Install Python 3.9+ (via deadsnakes PPA)
PYTHON_VERSION=$(python3 -V 2>&1 | awk '{print $2}')
REQUIRED_VERSION="3.9"

version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

if command -v python3 &> /dev/null && version_ge "$PYTHON_VERSION" "$REQUIRED_VERSION"; then
    echo "✅ Python $PYTHON_VERSION is already installed."
else
    echo "🐍 Installing Python 3.9..."
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update -y
    sudo apt install -y python3.9 python3.9-venv python3.9-distutils

    # Set Python 3.9 as default if needed
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
    echo "✅ Python 3.9 installed successfully."
fi

# Install pip if not available
if command -v pip3 &> /dev/null; then
    echo "✅ pip is already installed."
else
    echo "📦 Installing pip..."
    sudo apt install -y python3-pip
    echo "✅ pip installed successfully."
fi

# Install Django if not already present
if python3 -c "import django" &> /dev/null; then
    echo "✅ Django is already installed."
else
    echo "🌐 Installing Django..."
    pip3 install django
    echo "✅ Django installed successfully."
fi

# Display installed versions
echo ""
echo "🔍 Checking installed versions:"
docker --version
docker-compose --version
python3 --version
python3 -c "import django; print('Django', django.get_version())"

echo ""
echo "✅ Installation completed!"
echo "ℹ️  If this is your first time installing Docker, please log out and log back in to apply Docker group permissions."

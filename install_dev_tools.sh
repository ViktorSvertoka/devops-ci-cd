#!/bin/bash

echo "🔧 Починаємо встановлення DevOps-інструментів..."

# Оновлення системи та встановлення базових утиліт
echo "🔄 Оновлення списку пакетів..."
sudo apt update -y
sudo apt install -y software-properties-common curl

# Встановлення Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker вже встановлений."
else
    echo "🐳 Встановлюємо Docker..."
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "✅ Docker успішно встановлено."
fi

# Встановлення Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose вже встановлений."
else
    echo "🔧 Встановлюємо Docker Compose..."
    sudo apt install -y docker-compose
    echo "✅ Docker Compose успішно встановлено."
fi

# Встановлення Python 3.9+ (через deadsnakes/ppa)
PYTHON_VERSION=$(python3 -V 2>&1 | awk '{print $2}')
REQUIRED_VERSION="3.9"

version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

if command -v python3 &> /dev/null && version_ge "$PYTHON_VERSION" "$REQUIRED_VERSION"; then
    echo "✅ Python $PYTHON_VERSION вже встановлений."
else
    echo "🐍 Встановлюємо Python 3.9..."
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update -y
    sudo apt install -y python3.9 python3.9-venv python3.9-distutils

    # Створюємо alias, якщо треба
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
    echo "✅ Python 3.9 встановлено."
fi

# Встановлення pip, якщо його немає
if command -v pip3 &> /dev/null; then
    echo "✅ pip вже встановлений."
else
    echo "📦 Встановлюємо pip..."
    sudo apt install -y python3-pip
    echo "✅ pip встановлено."
fi

# Встановлення Django, якщо ще не встановлений
if python3 -c "import django" &> /dev/null; then
    echo "✅ Django вже встановлений."
else
    echo "🌐 Встановлюємо Django..."
    pip3 install django
    echo "✅ Django встановлено."
fi

# Перевірка версій встановлених інструментів
echo ""
echo "🔍 Перевірка встановлених версій:"
docker --version
docker-compose --version
python3 --version
python3 -c "import django; print('Django', django.get_version())"

echo ""
echo "✅ Встановлення завершено!"
echo "ℹ️  Якщо це перше встановлення Docker, вийдіть з системи та увійдіть знову, щоб застосувати права доступу до docker-групи."

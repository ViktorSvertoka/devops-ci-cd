# DevOps CI/CD

# Вивчення Helm — Lesson 7

## Опис проєкту

Даний проєкт демонструє повний цикл розгортання Django-застосунку у Kubernetes-кластері на базі AWS, із використанням Terraform для керування інфраструктурою та Helm для деплойменту застосунку.

Інфраструктура включає створення EKS-кластеру, приватного репозиторію ECR для зберігання Docker-образів та розгортання Helm-чарту, що забезпечує масштабування та конфігурацію сервісу.

## Структура проєкту

```
lesson-7/
│
├── main.tf                  # Основний Terraform-файл для підключення модулів
├── backend.tf               # Конфігурація бекенду (S3 + DynamoDB) для Terraform state
├── outputs.tf               # Глобальні вихідні дані інфраструктури
│
├── modules/                 # Каталог інфраструктурних модулів
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакету
│   │   ├── dynamodb.tf      # Створення таблиці DynamoDB
│   │   ├── variables.tf     # Змінні модуля
│   │   └── outputs.tf       # Вихідні дані
│   │
│   ├── vpc/                 # Модуль для створення VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж та Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутів
│   │   ├── variables.tf     # Змінні модуля
│   │   └── outputs.tf       # Вихідні дані
│   │
│   ├── ecr/                 # Модуль для ECR-репозиторію
│   │   ├── ecr.tf           # Створення приватного ECR
│   │   ├── variables.tf     # Змінні модуля
│   │   └── outputs.tf       # URL репозиторію
│   │
│   └── eks/                 # Модуль для створення EKS-кластеру
│       ├── eks.tf           # Створення EKS та Node Groups
│       ├── variables.tf     # Змінні модуля
│       └── outputs.tf       # Параметри кластера
│
├── charts/                  # Helm-чарти
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml    # Deployment для Django-застосунку
│       │   ├── service.yaml       # LoadBalancer Service
│       │   ├── configmap.yaml     # Змінні середовища
│       │   ├── hpa.yaml           # Horizontal Pod Autoscaler
│       │   └── _helpers.tpl       # Допоміжні шаблони Helm
│       ├── Chart.yaml             # Метадані чарта
│       └── values.yaml            # Конфігураційні значення
│
└── README.md                # Документація

```

#### Створена інфраструктура

- AWS-ресурси

  - EKS-кластер (Kubernetes 1.28)

  - EC2 Node Group (t3.medium, масштабування 2–6 нод)

  - VPC з публічними та приватними підмережами

  - ECR для зберігання Docker-образів

  - S3 для Terraform state

  - DynamoDB для блокування state

  - IAM-ролі та політики для EKS

- Kubernetes-ресурси

  - Deployment для Django-застосунку

  - LoadBalancer Service для зовнішнього доступу

  - ConfigMap зі змінними середовища

  - HorizontalPodAutoscaler для автоматичного масштабування

#### Перед початком роботи необхідно встановити та налаштувати:

- AWS CLI (з коректно налаштованими обліковими даними)

- Terraform (версія ≥ 1.0)

- kubectl

- Helm 3

- Docker

#### Інструкція з розгортання

1. Підготовка інфраструктури

```bash
# Ініціалізація Terraform
terraform init

# Перевірка плану змін
terraform plan

# Створення інфраструктури
terraform apply
```

2. Налаштування kubectl

```bash
# Підключення до EKS-кластеру
aws eks update-kubeconfig --region us-east-1 --name lesson-7-eks-cluster

# Перевірка доступу
kubectl get nodes
```

3. Підготовка Docker-образу

```bash
# Перехід на гілку з Django-проєктом
git checkout lesson-4

# Збірка образу без кешу
docker build --no-cache -t lesson-7-django-app .

# Логін у ECR
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Тегування
docker tag lesson-7-django-app:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/lesson-7-django-app:latest

# Завантаження
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/lesson-7-django-app:latest

```

4. Деплоймент застосунку через Helm

```bash
# Повернення на гілку з інфраструктурою
git checkout lesson-7
cd lesson-7

# Встановлення Helm-чарта
helm install django-app ./charts/django-app

# Перевірка статусу
helm status django-app
kubectl get all

```

5. Доступ до застосунку

```bash
# Отримання зовнішнього IP LoadBalancer
kubectl get service django-app

# Очікування (2–5 хв) на присвоєння IP
kubectl get service django-app -w

# Тестування
curl http://EXTERNAL-IP/health/

```

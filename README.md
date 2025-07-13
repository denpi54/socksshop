# Интернет-магазин "Sock Shop" в Yandex.Cloud

## 📦 Описание

Проект разворачивает микросервисный интернет-магазин по продаже носков (Sock Shop) в инфраструктуре Yandex.Cloud с использованием Docker Swarm и Terraform. Все компоненты описаны как код (IaC).

Проект состоит из следующих компонентов:

* Terraform-описание сети, подсети и трёх VM
* Установка Docker и конфигурация Swarm вручную
* Деплой микросервисов через `docker stack`

---

## 📁 Структура проекта

```
.
├── terraform/                    # Файлы инфраструктуры Terraform
│   ├── main.tf
│   └── variables.tf
├── docker-compose.yml           # Swarm-совместимый docker-compose
├── screenshots/                 # Скриншоты интерфейса и команд
├── README.md                    # Документация
```

---

## 🚀 Развёртывание

### 1. Клонируем репозиторий

```bash
git clone https://github.com/USERNAME/sockshop-iac-yandex.git
cd sockshop-iac-yandex
```

### 2. Устанавливаем переменные окружения

```bash
export TF_VAR_yc_token=<ВАШ_OAUTH_ТОКЕН>
```

### 3. Инициализация и запуск Terraform

```bash
cd terraform
terraform init
terraform apply
```

⏳ Подождите 3–5 минут, пока создаются 3 инстанса в Yandex.Cloud.

#### 📄 terraform/main.tf:

```hcl
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.97"
    }
  }
}

provider "yandex" {
  cloud_id  = "b1g5j0qn78dbkoi2o6ks"
  folder_id = "b1gbhkmqomeakg3ud104"
  zone      = "ru-central1-a"
  token     = var.yc_token
}

resource "yandex_vpc_network" "swarm_net" {
  name = "swarm-network"
}

resource "yandex_vpc_subnet" "swarm_subnet" {
  name           = "swarm-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.swarm_net.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_compute_instance" "swarm_node" {
  count       = 3
  name        = "swarm-node-${count.index + 1}"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.swarm_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}
```

#### 📄 terraform/variables.tf:

```hcl
variable "yc_token" {
  description = "OAuth token for Yandex.Cloud"
  type        = string
  sensitive   = true
}
```

---

## ⚙️ Установка Docker и настройка Docker Swarm

После создания VM подключитесь по SSH к каждой из них:

```bash
ssh ubuntu@<EXTERNAL_IP>
```

### На всех трёх узлах:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker ubuntu
newgrp docker
```

### На первом узле (менеджер):

```bash
docker swarm init --advertise-addr <PRIVATE_IP_MANAGER>
```

Скопируйте команду `docker swarm join ...`, которая появится после инициализации.

### На двух других узлах:

```bash
# Пример:
docker swarm join --token SWMTKN-... <PRIVATE_IP_MANAGER>:2377
```

Проверка:

```bash
docker node ls
```

---

## 📥 Деплой микросервисов

На **менеджер-ноде**, в каталоге с файлом `docker-compose.yml`:

```bash
docker stack deploy -c docker-compose.yml sockshop
```

Проверка статуса:

```bash
docker stack services sockshop
```

#### 📄 docker-compose.yml

\[Файл приведён отдельно, так как он большой. Я добавлю его в этот репозиторий отдельно.]

---

## 🌐 Проверка доступа

Откройте браузер и перейдите по публичному IP **менеджер-ноды**:

```
http://<EXTERNAL_IP>
```

---

## 📸 Скриншоты

1. `screenshots/browser_view.png` — отображение сайта с адресной строкой
2. `screenshots/docker_services.png` — вывод `docker service ls`
3. `screenshots/docker_nodes.png` — вывод `docker node ls`

---

## ✅ Завершение

После демонстрации:

```bash
terraform destroy
```

---

## 🧠 Полезные ссылки

* Sock Shop GitHub: [https://github.com/microservices-demo/microservices-demo](https://github.com/microservices-demo/microservices-demo)
* Terraform Yandex Provider: [https://registry.terraform.io/providers/yandex-cloud/yandex/latest](https://registry.terraform.io/providers/yandex-cloud/yandex/latest)


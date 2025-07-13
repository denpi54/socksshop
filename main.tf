terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.97"
    }
  }
}

provider "yandex" {
  service_account_key_file = "${path.module}/key.json"  # Или token = "..."
  cloud_id  = ""
  folder_id = ""
  zone      = "ru-central1-a"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
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


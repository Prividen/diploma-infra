# VMs resources
# master nodes
resource "yandex_compute_instance" "kube_control_plane" {
  count    = local.k8s_cluster_resources[local.ws].masters.count
  name     = "kb-master-${count.index}"
  hostname = "kb-master-${count.index}"
  # distribute VM instances across available zones/subnets
  zone = local.networks[count.index - floor(count.index / length(local.networks)) * length(local.networks)].zone_name

  resources {
    cores  = local.k8s_cluster_resources[local.ws].masters.cpu
    memory = local.k8s_cluster_resources[local.ws].masters.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.alma8.id
      type     = local.k8s_cluster_resources[local.ws].masters.disk_type
      size     = local.k8s_cluster_resources[local.ws].masters.disk
    }
  }

  network_interface {
    # distribute VM instances across available zones/subnets
    subnet_id = yandex_vpc_subnet.public[count.index - floor(count.index / length(local.networks)) * length(local.networks)].id
    nat       = true
  }

  scheduling_policy {
    preemptible = local.k8s_cluster_resources[local.ws].masters.preemptible
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_ed25519_yandex.pub")}"
  }
}


# worker nodes
resource "yandex_compute_instance" "kube_node" {
  count    = local.k8s_cluster_resources[local.ws].workers.count
  name     = "kb-worker-${count.index}"
  hostname = "kb-worker-${count.index}"
  # distribute VM instances across available zones/subnets
  zone = local.networks[count.index - floor(count.index / length(local.networks)) * length(local.networks)].zone_name


  resources {
    cores  = local.k8s_cluster_resources[local.ws].workers.cpu
    memory = local.k8s_cluster_resources[local.ws].workers.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.alma8.id
      type     = local.k8s_cluster_resources[local.ws].workers.disk_type
      size     = local.k8s_cluster_resources[local.ws].workers.disk
    }
  }

  network_interface {
    # distribute VM instances across available zones/subnets
    subnet_id = yandex_vpc_subnet.public[count.index - floor(count.index / length(local.networks)) * length(local.networks)].id
    nat       = true
  }

  scheduling_policy {
    preemptible = local.k8s_cluster_resources[local.ws].workers.preemptible
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_ed25519_yandex.pub")}"
  }
}


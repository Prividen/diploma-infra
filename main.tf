provider "yandex" {
  cloud_id                 = "b1gh0k7cb2gn2mh9i1uc"
  folder_id                = "b1g200bppkibol684gqj"
  zone                     = local.default_zone
}

# set by TFC only
variable "TFC_WORKSPACE_NAME" {
  type    = string
  default = ""
}

# take workspace name without prefix
locals {
  ws = var.TFC_WORKSPACE_NAME != "" ? (
    trimprefix(var.TFC_WORKSPACE_NAME, "yc-")
    ) : (
    trimprefix(terraform.workspace, "yc-")
  )

  networks = [
    {
      zone_name = "ru-central1-a"
      subnet    = ["192.168.10.0/24"]
    },
    {
      zone_name = "ru-central1-b"
      subnet    = ["192.168.11.0/24"]
    },
    {
      zone_name = "ru-central1-c"
      subnet    = ["192.168.12.0/24"]
    }
  ]

  cloud_id     = "b1gh0k7cb2gn2mh9i1uc"
  folder_id    = "b1g200bppkibol684gqj"
  default_zone = local.networks.0.zone_name
  dns_zone     = "yc.complife.ru"
  cluster_name = "kube-cluster"
  control_url   = "${local.cluster_name}.${local.dns_zone}"
  ingress_url   = "${local.cluster_name}-ingress.${local.dns_zone}"

  k8s_cluster_resources = {
    stage = {
      masters = {
        count       = 1
        cpu         = 4
        memory      = 4
        disk        = 93
        disk_type   = "network-ssd-nonreplicated"
        preemptible = true
      }
      workers = {
        count       = 3
        cpu         = 2
        memory      = 4
        disk        = 20
        disk_type   = "network-ssd"
        preemptible = true
      }
    }
    prod = {
      masters = {
        count       = 1
        cpu         = 4
        memory      = 4
        disk        = 93
        disk_type   = "network-ssd-nonreplicated"
        preemptible = false
      }
      workers = {
        count       = 6
        cpu         = 2
        memory      = 4
        disk        = 20
        disk_type   = "network-ssd"
        preemptible = false
      }
    }
  }
}


# AlmaLinux 8 image
data "yandex_compute_image" "alma8" {
  family = "almalinux-8"
}

# Network resources
resource "yandex_vpc_network" "vpc-diploma" {
  name = "vpc-diploma"
}

resource "yandex_vpc_subnet" "public" {
  count          = length(local.networks)
  v4_cidr_blocks = local.networks[count.index].subnet
  zone           = local.networks[count.index].zone_name
  network_id     = yandex_vpc_network.vpc-diploma.id
  name           = "subnet-${local.networks[count.index].zone_name}"
}

# VMs resources
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
    ssh-keys = "cloud-user:${file("~/.ssh/id_ed25519.pub")}"
  }
}


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
    ssh-keys = "cloud-user:${file("~/.ssh/id_ed25519.pub")}"
  }
}


# create DNS zone with names for cluster resources
resource "yandex_dns_zone" "dns-zone-yc" {
  name   = "dns-zone-yc"
  zone   = "${local.dns_zone}."
  public = true
}


resource "yandex_dns_recordset" "dns-record-kube-cluster-control" {
  zone_id = yandex_dns_zone.dns-zone-yc.id
  name    = local.cluster_name
  type    = "A"
  ttl     = 200
  data    = yandex_compute_instance.kube_control_plane.*.network_interface.0.nat_ip_address
  depends_on = [yandex_compute_instance.kube_control_plane]
}

# as we use ingress controller with hostNetwork mode, we assign to ingress name IP of all worker nodes
resource "yandex_dns_recordset" "dns-record-kube-cluster-ingress" {
  zone_id = yandex_dns_zone.dns-zone-yc.id
  name    = "${local.cluster_name}-ingress"
  type    = "A"
  ttl     = 200
  data    = yandex_compute_instance.kube_node.*.network_interface.0.nat_ip_address
  depends_on = [yandex_compute_instance.kube_node]
}

# following names just CNAME for ingress
resource "yandex_dns_recordset" "dns-record-kube-cluster-dashboard" {
  zone_id = yandex_dns_zone.dns-zone-yc.id
  name    = "${local.cluster_name}-dashboard"
  type    = "CNAME"
  ttl     = 200
  data    = [local.ingress_url]
}

resource "yandex_dns_recordset" "dns-record-grafana" {
  zone_id = yandex_dns_zone.dns-zone-yc.id
  name    = "grafana"
  type    = "CNAME"
  ttl     = 200
  data    = [local.ingress_url]
}

resource "yandex_dns_recordset" "dns-record-testapp" {
  zone_id = yandex_dns_zone.dns-zone-yc.id
  name    = "testapp"
  type    = "CNAME"
  ttl     = 200
  data    = [local.ingress_url]
}

resource "yandex_dns_recordset" "dns-record-testapp-stage" {
  zone_id = yandex_dns_zone.dns-zone-yc.id
  name    = "testapp-stage"
  type    = "CNAME"
  ttl     = 200
  data    = [local.ingress_url]
}


# create private container registry
resource "yandex_container_registry" "diploma-registry" {
  name = "diploma-registry"
}

# and repository for testapp (probably, useless)
resource "yandex_container_repository" "testapp-repository" {
  name = "${yandex_container_registry.diploma-registry.id}/testapp"
  depends_on = [yandex_container_registry.diploma-registry]
}

# and pusher and puller service accounts with roles for this registry
resource "yandex_iam_service_account" "k8s-registry-agent" {
  name      = "k8s-registry-agent"
}

resource "yandex_container_registry_iam_binding" "k8s-registry-agent-puller" {
  registry_id = yandex_container_registry.diploma-registry.id
  role      = "container-registry.images.puller"
  members    = ["serviceAccount:${yandex_iam_service_account.k8s-registry-agent.id}"]
  depends_on = [
    yandex_iam_service_account.k8s-registry-agent,
    yandex_container_registry.diploma-registry
  ]
}

resource "yandex_iam_service_account_key" "k8s-registry-agent-key" {
  service_account_id = yandex_iam_service_account.k8s-registry-agent.id
  description        = "SA key for k8s registry agent"
  depends_on = [yandex_iam_service_account.k8s-registry-agent]
}

resource "yandex_iam_service_account" "docker-registry-agent" {
  name      = "docker-registry-agent"
}

resource "yandex_container_registry_iam_binding" "docker-registry-agent-pusher" {
  registry_id =     yandex_container_registry.diploma-registry.id
  role      = "container-registry.images.pusher"
  members    = ["serviceAccount:${yandex_iam_service_account.docker-registry-agent.id}"]
  depends_on = [
    yandex_iam_service_account.docker-registry-agent,
    yandex_container_registry.diploma-registry
  ]
}

resource "yandex_iam_service_account_key" "docker-registry-agent-key" {
  service_account_id = yandex_iam_service_account.docker-registry-agent.id
  description        = "SA key for docker registry agent"
  depends_on = [yandex_iam_service_account.docker-registry-agent]
}



# some static content we'll place in storage bucket.
# create service account, its keys, storage bucket and picture object
resource "yandex_iam_service_account" "storage-agent" {
  name      = "storage-agent"
}

resource "yandex_resourcemanager_folder_iam_member" "storage-agent-editor" {
  folder_id = yandex_iam_service_account.storage-agent.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage-agent.id}"
  depends_on = [yandex_iam_service_account.storage-agent]
}

resource "yandex_iam_service_account_static_access_key" "storage-agent-static-key" {
  service_account_id = yandex_iam_service_account.storage-agent.id
  description        = "static access key for object storage"
  depends_on = [yandex_iam_service_account.storage-agent]
}

resource "yandex_storage_bucket" "netology-diploma" {
  access_key = yandex_iam_service_account_static_access_key.storage-agent-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage-agent-static-key.secret_key
  depends_on = [
    yandex_iam_service_account_static_access_key.storage-agent-static-key
  ]
  bucket = "netology-diploma"
  acl = "public-read"
}

resource "yandex_storage_object"  "cat" {
  access_key = yandex_iam_service_account_static_access_key.storage-agent-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage-agent-static-key.secret_key
  depends_on = [yandex_iam_service_account_static_access_key.storage-agent-static-key]
  bucket = yandex_storage_bucket.netology-diploma.bucket
  key = "cat.jpg"
  content_type = "image/jpeg"
  source = "cat.jpg"
  acl = "public-read"
}

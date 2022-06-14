provider "yandex" {
  cloud_id  = "b1gh0k7cb2gn2mh9i1uc"
  folder_id = "b1g200bppkibol684gqj"
  zone      = local.default_zone
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
  control_url  = "${local.cluster_name}.${local.dns_zone}"
  ingress_url  = "${local.cluster_name}-ingress.${local.dns_zone}"

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

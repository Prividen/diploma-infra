# create DNS zone with names for cluster resources
resource "yandex_dns_zone" "dns-zone-yc" {
  name   = "dns-zone-yc"
  zone   = "${local.dns_zone}."
  public = true
}


resource "yandex_dns_recordset" "dns-record-kube-cluster-control" {
  zone_id    = yandex_dns_zone.dns-zone-yc.id
  name       = local.cluster_name
  type       = "A"
  ttl        = 200
  data       = yandex_compute_instance.kube_control_plane.*.network_interface.0.nat_ip_address
  depends_on = [yandex_compute_instance.kube_control_plane]
}

# as we use ingress controller with hostNetwork mode, we assign to ingress name IP of all worker nodes
resource "yandex_dns_recordset" "dns-record-kube-cluster-ingress" {
  zone_id    = yandex_dns_zone.dns-zone-yc.id
  name       = "${local.cluster_name}-ingress"
  type       = "A"
  ttl        = 200
  data       = yandex_compute_instance.kube_node.*.network_interface.0.nat_ip_address
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

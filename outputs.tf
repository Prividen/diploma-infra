# these values will be added to the cluster certificate
output "supplementary_addresses_in_ssl_keys" {
  value = concat(
    tolist(["${local.cluster_name}.${local.dns_zone}"]),
    tolist(yandex_dns_recordset.dns-record-kube-cluster-control.data)
  )
}

# User which we use to connect to VM, Ansible need it
output "ansible_user" {
  value = "cloud-user"
}

output "container_registry" {
  value = "cr.yandex/${yandex_container_registry.diploma-registry.id}"
}

output "master_nodes" {
  value = yandex_compute_instance.kube_control_plane.*.network_interface.0.nat_ip_address
}

output "worker_nodes" {
  value = yandex_compute_instance.kube_node.*.network_interface.0.nat_ip_address
}

output "access_urls" {
  value = {
    Control   = "${local.control_url}"
    Ingress   = "${local.ingress_url}"
    Dashboard = "${local.cluster_name}-dashboard.${local.dns_zone}"
    Grafana   = "grafana.${local.dns_zone}"
    Testapp = {
      prod  = "http://testapp.${local.dns_zone}"
      stage = "http://testapp-stage.${local.dns_zone}"
    }
  }
}

output "picture_url" {
  value = "https://storage.yandexcloud.net/${yandex_storage_bucket.netology-diploma.bucket}/${yandex_storage_object.cat.key}"
}

output "k8s_registry_agent_key" {
  value = {
    id                 = yandex_iam_service_account_key.k8s-registry-agent-key.id
    service_account_id = yandex_iam_service_account_key.k8s-registry-agent-key.service_account_id
    created_at         = yandex_iam_service_account_key.k8s-registry-agent-key.created_at
    key_algorithm      = yandex_iam_service_account_key.k8s-registry-agent-key.key_algorithm
    public_key         = yandex_iam_service_account_key.k8s-registry-agent-key.public_key
    private_key        = yandex_iam_service_account_key.k8s-registry-agent-key.private_key
  }
  sensitive = true
}

output "docker_registry_agent_key" {
  value = {
    id                 = yandex_iam_service_account_key.docker-registry-agent-key.id
    service_account_id = yandex_iam_service_account_key.docker-registry-agent-key.service_account_id
    created_at         = yandex_iam_service_account_key.docker-registry-agent-key.created_at
    key_algorithm      = yandex_iam_service_account_key.docker-registry-agent-key.key_algorithm
    public_key         = yandex_iam_service_account_key.docker-registry-agent-key.public_key
    private_key        = yandex_iam_service_account_key.docker-registry-agent-key.private_key
  }
  sensitive = true
}

output "deploy_env" {
  value = local.ws
}

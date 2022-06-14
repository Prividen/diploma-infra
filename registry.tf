# Here we create an image registry and two SA - puller (k8s) and pusher (docker)

# create private container registry
resource "yandex_container_registry" "diploma-registry" {
  name = "diploma-registry"
}

# and repository for testapp (probably, useless)
resource "yandex_container_repository" "testapp-repository" {
  name = "${yandex_container_registry.diploma-registry.id}/testapp"
  depends_on = [
    yandex_container_registry.diploma-registry
  ]
}

# and pusher and puller service accounts with roles for this registry
resource "yandex_iam_service_account" "k8s-registry-agent" {
  name = "k8s-registry-agent"
}

resource "yandex_container_registry_iam_binding" "k8s-registry-agent-puller" {
  registry_id = yandex_container_registry.diploma-registry.id
  role        = "container-registry.images.puller"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s-registry-agent.id}"
  ]
  depends_on = [
    yandex_iam_service_account.k8s-registry-agent,
    yandex_container_registry.diploma-registry
  ]
}

resource "yandex_iam_service_account_key" "k8s-registry-agent-key" {
  service_account_id = yandex_iam_service_account.k8s-registry-agent.id
  description        = "SA key for k8s registry agent"
  depends_on = [
    yandex_iam_service_account.k8s-registry-agent
  ]
}

resource "yandex_iam_service_account" "docker-registry-agent" {
  name = "docker-registry-agent"
}

resource "yandex_container_registry_iam_binding" "docker-registry-agent-pusher" {
  registry_id = yandex_container_registry.diploma-registry.id
  role        = "container-registry.images.pusher"
  members     = ["serviceAccount:${yandex_iam_service_account.docker-registry-agent.id}"]
  depends_on = [
    yandex_iam_service_account.docker-registry-agent,
    yandex_container_registry.diploma-registry
  ]
}

resource "yandex_iam_service_account_key" "docker-registry-agent-key" {
  service_account_id = yandex_iam_service_account.docker-registry-agent.id
  description        = "SA key for docker registry agent"
  depends_on = [
    yandex_iam_service_account.docker-registry-agent
  ]
}

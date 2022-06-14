# some static content we'll place in storage bucket.
# create service account, its keys, storage bucket and picture object
resource "yandex_iam_service_account" "storage-agent" {
  name = "storage-agent"
}

resource "yandex_resourcemanager_folder_iam_member" "storage-agent-editor" {
  folder_id = yandex_iam_service_account.storage-agent.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage-agent.id}"
  depends_on = [
    yandex_iam_service_account.storage-agent
  ]
}

resource "yandex_iam_service_account_static_access_key" "storage-agent-static-key" {
  service_account_id = yandex_iam_service_account.storage-agent.id
  description        = "static access key for object storage"
  depends_on = [
    yandex_iam_service_account.storage-agent
  ]
}

resource "yandex_storage_bucket" "netology-diploma" {
  access_key = yandex_iam_service_account_static_access_key.storage-agent-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage-agent-static-key.secret_key
  depends_on = [
    yandex_iam_service_account_static_access_key.storage-agent-static-key
  ]
  bucket = "netology-diploma"
  acl    = "public-read"
}

resource "yandex_storage_object" "cat" {
  access_key = yandex_iam_service_account_static_access_key.storage-agent-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage-agent-static-key.secret_key
  depends_on = [
    yandex_iam_service_account.storage-agent,
    yandex_iam_service_account_static_access_key.storage-agent-static-key,
    yandex_resourcemanager_folder_iam_member.storage-agent-editor,
    yandex_storage_bucket.netology-diploma
  ]
  bucket       = yandex_storage_bucket.netology-diploma.bucket
  key          = "cat.jpg"
  content_type = "image/jpeg"
  source       = "cat.jpg"
  acl          = "public-read"
}

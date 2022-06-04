terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.73.0"
    }
  }

  cloud {
    organization = "prividen-test-org"
    hostname     = "app.terraform.io"

    workspaces {
      tags = ["yc-diploma"]
    }
  }
}

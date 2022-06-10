terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      # 0.74 has a bug with S3 creation
      # https://github.com/yandex-cloud/terraform-provider-yandex/issues/261
      version = "0.73.0"
    }
  }

  cloud {
    organization = "prividen-test-org"
    hostname     = "app.terraform.io"

    # TFC workspaces for this project
    workspaces {
      tags = ["yc-diploma"]
    }
  }
}

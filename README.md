# Infrastructure

This project contain infrastructure part:
- cloud resources (terraform)
- k8s cluster installation (ansible/kubespray)
- k8s addons (dashboard, kube-prometheus) installation (ansible)
- ci/cd pipeline for all these deployments, and triggering testapp deployment as well

(Resources for test application are in separate [project](https://github.com/Prividen/diploma-testapp))


## Cloud resources
There are [Yandex cloud](https://cloud.yandex.ru) using in this project, and Terraform has access with its dedicated service account, provided in 
CI/CD as `YC_SERVICE_ACCOUNT_KEY_FILE` variable.

Terraform states are stored in Terraform cloud (CI/CD uses `TF_TOKEN_app_terraform_io` variable
to access it).

Two workspaces used, `yc-stage` and `yc-prod` (translates internally to `stage`/`prod`), configured by `TF_WORKSPACE` variable.

In addition to K8s cluster resources, an S3 backet created to keep [static content](cat.jpg) for test application.

## K8s cluster
Ansible uses [terraform-inventory project](https://github.com/adammck/terraform-inventory) as a dynamic inventory, to 
inherit hosts info from Terraform states, and all Terraform outputs are also available as Ansible vars.

SSH keys provides in CI/CD `ssh_key_pub` and `ssh_key_priv` variables.

All Kubespray customizations are located in [custom-inventory](custom-inventory) directory, connected as an additional inventory,
so CI process can git-clone and run unchanged Kubespray to deploy a cluster. 

NGINX Ingress Controller installed with `hostNetwork` option, it should be the easiest way to configure network access on 
80/443 ports without cloud-related `loadBalancer` Service, or the own MetalLB load balancer which one require additional IP.

## K8s addons
Cluster access info are imported in separate config file, provides further in `KUBECONFIG` variable.

Certificate for TLS access to addons provides in `tls_crt` and `tls_priv` CI/CD variables.

Dashboard access info stored in yaml file which available as artifact after pipeline run.

Predefined Grafana password provided in `grafana_pass` CI/CD variable.


# CI/CD
All tests/deploy operations running in a special container with all necessary tools and utilities installed, 
its image build from [infra-container](infra-container) folder content.

Final job saves some artifacts (cluster access config, infrastructure description) for further testapp CI/CD, and 
triggers its pipeline upon success cluster deployment. 

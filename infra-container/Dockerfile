FROM python:3
ARG ansible_version=5.8.0
ARG ansible_core_version=2.12.6
ARG ansible_lint_version=6.2.1
ARG kubernetes_version=23.6.0
ARG terraform_version=1.2.1
ARG terraform_inventory_version=0.10
ARG jsonnet_builder_version=0.4.0
ARG jsonnet_version=0.18.0
ARG kubectl_version=1.24.1
ARG qbeq_version=0.15.2
ARG helm_version=3.9.0
ARG terraform_url="https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip"
ARG terraform_inventory_url="https://github.com/adammck/terraform-inventory/releases/download/v${terraform_inventory_version}/terraform-inventory_v${terraform_inventory_version}_linux_amd64.zip"
ARG jsonnet_url="https://github.com/google/go-jsonnet/releases/download/v${jsonnet_version}/jsonnet-go_${jsonnet_version}_linux_amd64.deb"
ARG jsonnet_builder_url="https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/v${jsonnet_builder_version}/jb-linux-amd64"
ARG kubectl_url="https://dl.k8s.io/release/v${kubectl_version}/bin/linux/amd64/kubectl"
ARG qbec_url="https://github.com/splunk/qbec/releases/download/v${qbeq_version}/qbec-linux-amd64.tar.gz"
ARG helm_url="https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz"

RUN cd /tmp &&  \
    curl -sL "${terraform_url}" -o terraform.zip && \
    curl -sL "${terraform_inventory_url}" -o terraform_inventory.zip && \
    curl -sL "${jsonnet_url}" -o jsonnet.deb  && \
    curl -sL "${jsonnet_builder_url}" -o jb  && \
    curl -sL "${kubectl_url}" -o kubectl && \
    curl -sL "${qbec_url}" -o qbec.tgz && \
    curl -sL "${helm_url}" -o helm.tgz && \
    unzip terraform.zip && chmod 0755 terraform && mv terraform /usr/local/bin/ && \
    unzip terraform_inventory.zip &&  \
    chmod 0755 terraform-inventory && mv terraform-inventory /usr/local/bin/ && \
    dpkg -i jsonnet.deb && \
    chmod 0755 jb && mv jb /usr/local/bin/ && \
    chmod 0755 kubectl && mv kubectl /usr/local/bin/ && \
    tar -xf qbec.tgz && chmod 0755 qbec && chown root: qbec && mv qbec /usr/local/bin/ && \
    tar -xf helm.tgz && (cd linux-amd64 && chmod 0755 helm && chown root: helm && mv helm /usr/local/bin/ ) && \
    rm -rf * && \
    apt-get update && apt-get install -y \
      jq \
      sudo \
      vim && \
    apt-get clean

RUN   pip install \
        "ansible==${ansible_version}" \
        "ansible-core==${ansible_core_version}" \
        "ansible-lint==${ansible_lint_version}" \
        "kubernetes==${kubernetes_version}" \
        ipaddr \
        netaddr \
        jsonpath && \
      pip cache purge

COPY prepare_env.sh /prepare_env.sh

RUN   mkdir /etc/ansible/ && \
      chmod 0755 /prepare_env.sh && \
      useradd -m -G sudo deployer && echo '%sudo        ALL=(ALL:ALL) NOPASSWD:ALL' >/etc/sudoers.d/nopasswd

COPY ansible.cfg /etc/ansible/ansible.cfg

USER deployer

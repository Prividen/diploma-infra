#!/bin/bash

mkdir ~/.ssh
mkdir -p .secrets

if [ -n "$ssh_key_pub" ]; then
  cp "$ssh_key_pub" ~/.ssh/id_ed25519.pub
  ln -s id_ed25519.pub ~/.ssh/id_ed25519_yandex.pub
fi

if [ -n "$ssh_key_priv" ]; then
  cp "$ssh_key_priv" ~/.ssh/id_ed25519
  rm -f "$ssh_key_priv"
  chmod 0600 ~/.ssh/id_ed25519
fi

if [ -n "$tls_crt" ]; then
  cp "$tls_crt" .secrets/tls.crt
fi

if [ -n "$tls_priv" ]; then
  cp "$tls_priv" .secrets/tls.key
  rm -f "$tls_priv"
  chmod 0600 .secrets/tls.key
fi

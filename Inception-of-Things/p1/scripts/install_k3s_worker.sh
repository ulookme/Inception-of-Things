#!/bin/bash
set -e
SERVER_IP="192.168.56.110"
TOKEN="$(cat /home/vagrant/node-token || true)"
if [ -z "$TOKEN" ]; then
  # si le partage /vagrant existe (Parallels le monte), on lit là:
  [ -f /vagrant/node-token ] && TOKEN="$(cat /vagrant/node-token)"
fi
if [ -z "$TOKEN" ]; then
  echo "Token introuvable. Assure-toi que luqmanS est provisionné avant le worker."
  exit 1
fi
curl -sfL https://get.k3s.io | K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$TOKEN" sh -


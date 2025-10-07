#!/bin/bash
set -e
curl -sfL https://get.k3s.io | sh -
sudo cat /var/lib/rancher/k3s/server/node-token | sudo tee /vagrant/node-token >/dev/null

#!/bin/bash
set -e
curl -sfL https://get.k3s.io | sh -
sudo cat /var/lib/rancher/k3s/server/node-token | sudo tee /home/vagrant/node-token >/dev/null
sudo chown vagrant:vagrant /home/vagrant/node-token


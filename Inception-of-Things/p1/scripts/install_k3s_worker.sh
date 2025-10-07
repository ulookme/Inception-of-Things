#!/bin/bash
set -e
SERVER_IP="192.168.56.110"

# Attendre que le token soit disponible
echo "Attente du token du serveur..."
while [ ! -f /vagrant/node-token ]; do
  sleep 2
done

TOKEN="$(cat /vagrant/node-token)"

if [ -z "$TOKEN" ]; then
  echo "ERREUR: Token vide!"
  exit 1
fi

echo "Token trouvé, démarrage de l'agent K3s..."
curl -sfL https://get.k3s.io | K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$TOKEN" sh -

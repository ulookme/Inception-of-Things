#!/usr/bin/env bash
set -euo pipefail

echo "=== Lancement de GitLab CE localement ==="

GITLAB_CONTAINER="gitlab-ce"
GITLAB_HOME="${HOME}/gitlab-data"
HTTP_PORT=8081
HTTPS_PORT=9443
SSH_PORT=2223

# Créer les dossiers de données
mkdir -p "${GITLAB_HOME}"/{config,logs,data}

# Vérifier si GitLab existe déjà
if docker ps -a --format '{{.Names}}' | grep -q "^${GITLAB_CONTAINER}$"; then
  echo "[i] Container GitLab existant détecté. Suppression..."
  docker rm -f "${GITLAB_CONTAINER}" >/dev/null 2>&1 || true
fi

echo "[+] Démarrage du container GitLab..."
docker run -d \
  --hostname gitlab.local \
  --name "${GITLAB_CONTAINER}" \
  --restart unless-stopped \
  -p ${HTTP_PORT}:80 \
  -p ${HTTPS_PORT}:443 \
  -p ${SSH_PORT}:22 \
  -v "${GITLAB_HOME}/config:/etc/gitlab" \
  -v "${GITLAB_HOME}/logs:/var/log/gitlab" \
  -v "${GITLAB_HOME}/data:/var/opt/gitlab" \
  gitlab/gitlab-ce:latest

echo ""
echo "[i] GitLab démarre... Cela peut prendre 2-5 minutes."
echo "[i] Attente de l'initialisation..."

# Attendre que GitLab soit prêt
MAX_WAIT=600
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
  if docker exec "${GITLAB_CONTAINER}" test -f /etc/gitlab/initial_root_password 2>/dev/null; then
    PASSWORD=$(docker exec "${GITLAB_CONTAINER}" grep 'Password:' /etc/gitlab/initial_root_password | awk '{print $2}')
    if [ -n "${PASSWORD}" ]; then
      echo "${PASSWORD}" > scripts/gitlab_root_password.txt
      chmod 600 scripts/gitlab_root_password.txt
      break
    fi
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
  printf "."
done

echo ""
echo ""
echo "============================================"
echo "✓ GitLab est prêt!"
echo "============================================"
echo ""
echo "URL       : http://localhost:${HTTP_PORT}"
echo "Username  : root"
echo "Password  : ${PASSWORD}"
echo ""
echo "Le mot de passe est sauvegardé dans: scripts/gitlab_root_password.txt"
echo ""
echo "PROCHAINE ÉTAPE:"
echo "  1. Ouvrir http://localhost:${HTTP_PORT}"
echo "  2. Se connecter avec root / ${PASSWORD}"
echo "  3. Exécuter: ./scripts/02_setup_k3d.sh"
echo "============================================"
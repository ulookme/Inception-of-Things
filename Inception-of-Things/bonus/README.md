# Inception-of-Things - Bonus: GitLab Integration

## Description
Ce bonus ajoute GitLab à l'infrastructure de la Partie 3, permettant un workflow CI/CD complet avec GitLab local au lieu de GitHub.

## Architecture

```
┌─────────────┐
│   GitLab    │ (Docker)
│  localhost  │
│   :8080     │
└──────┬──────┘
       │
       │ sync
       ▼
┌─────────────────────────────────┐
│         K3d Cluster             │
│                                 │
│  ┌──────────┐   ┌───────────┐  │
│  │  Argo CD │──>│    dev    │  │
│  │namespace │   │ namespace │  │
│  └──────────┘   └───────────┘  │
│                                 │
│  ┌──────────┐                   │
│  │  gitlab  │                   │
│  │namespace │                   │
│  └──────────┘                   │
└─────────────────────────────────┘
```

## Prérequis

- Docker Desktop installé et démarré
- Homebrew (macOS)
- 8 GB RAM minimum
- 20 GB d'espace disque

## Installation complète

### Étape 1: Lancer GitLab

```bash
cd bonus
chmod +x scripts/*.sh
./scripts/01_start_gitlab.sh
```

**Durée: 2-5 minutes**

Cela va:
- Télécharger l'image GitLab CE
- Démarrer GitLab dans Docker
- Créer le mot de passe root initial
- Sauvegarder les identifiants

### Étape 2: Créer le cluster K3d

```bash
./scripts/02_setup_k3d.sh
```

**Durée: 3-5 minutes**

Cela va:
- Installer K3d et kubectl
- Créer un cluster K3d avec 2 agents
- Créer les namespaces: argocd, gitlab, dev
- Installer Argo CD
- Démarrer le port-forward

### Étape 3: Configurer GitLab (MANUEL)

```bash
./scripts/03_configure_gitlab.sh
```

**Suivre les instructions affichées:**

1. Ouvrir http://localhost:8080
2. Se connecter avec:
   - Username: `root`
   - Password: (voir `scripts/gitlab_root_password.txt`)

3. Créer un nouveau projet:
   - Menu: New project > Create blank project
   - Project name: `iot-deployment`
   - Visibility: **Public**
   - Décocher "Initialize repository with a README"
   - Create project

4. Créer un Personal Access Token:
   - Menu: User Settings (icône en haut à droite) > Access Tokens
   - Token name: `argocd`
   - Expiration: Laisser vide
   - Scopes: cocher `api` et `read_repository`
   - Create personal access token
   - **COPIER LE TOKEN** et le sauvegarder dans `scripts/gitlab_token.txt`

5. Pousser le code vers GitLab:

```bash
cd confs/
git init
git add .
git commit -m "Initial commit with v1"
git remote add origin http://localhost:8080/root/iot-deployment.git
git branch -M main
git push -u origin main
```

Credentials:
- Username: `root`
- Password: (le mot de passe root GitLab)

### Étape 4: Connecter Argo CD à GitLab

```bash
cd ..  # Retour au dossier bonus/
./scripts/04_setup_argocd.sh
```

Cela va:
- Configurer Argo CD pour utiliser GitLab
- Déployer l'application via Argo CD
- Vérifier que tout fonctionne

## Vérifications

### 1. GitLab est accessible
```bash
curl http://localhost:8080
```

### 2. Les namespaces existent
```bash
kubectl get ns
```

Doit afficher: `argocd`, `gitlab`, `dev`

### 3. L'application tourne
```bash
kubectl get pods -n dev
```

Doit afficher un pod `playground-app-*` en état `Running`

### 4. L'application répond
```bash
curl http://localhost:8888
```

Doit retourner: `{"status":"ok", "message": "v1"}`

### 5. Argo CD affiche l'application
- Ouvrir http://localhost:8090
- Login: `admin`
- Password: (voir `scripts/argocd_password.txt`)
- Voir l'application `playground-app` synchronisée

## Test du CI/CD complet

### Changer la version de v1 à v2

```bash
cd confs/
sed -i '' 's/playground:v1/playground:v2/g' deployment.yaml
git add deployment.yaml
git commit -m "Update to v2"
git push
```

### Vérifier la synchronisation

1. Dans Argo CD (http://localhost:8090):
   - L'application doit passer en "OutOfSync"
   - Puis se synchroniser automatiquement
   - Revenir à "Synced"

2. Vérifier la nouvelle version:
```bash
curl http://localhost:8888
```

Doit retourner: `{"status":"ok", "message": "v2"}`

3. Vérifier le pod:
```bash
kubectl get pods -n dev
kubectl describe pod -n dev playground-app-<id> | grep Image
```

Doit afficher: `wil42/playground:v2`

## Ports utilisés

| Service | Port | URL |
|---------|------|-----|
| GitLab HTTP | 8080 | http://localhost:8080 |
| GitLab HTTPS | 8443 | https://localhost:8443 |
| GitLab SSH | 2222 | ssh://git@localhost:2222 |
| Argo CD | 8090 | http://localhost:8090 |
| Application | 8888 | http://localhost:8888 |

## Commandes utiles

### GitLab

```bash
# Voir les logs GitLab
docker logs -f gitlab-ce

# Redémarrer GitLab
docker restart gitlab-ce

# Arrêter GitLab
docker stop gitlab-ce

# Supprimer GitLab (⚠️ perte des données)
docker rm -f gitlab-ce
rm -rf ~/gitlab-data
```

### K3d

```bash
# Voir les clusters
k3d cluster list

# Arrêter le cluster
k3d cluster stop iot-bonus

# Redémarrer le cluster
k3d cluster start iot-bonus

# Supprimer le cluster
k3d cluster delete iot-bonus
```

### Argo CD

```bash
# Voir les applications
kubectl get applications -n argocd

# Voir les détails
kubectl describe application playground-app -n argocd

# Forcer une synchronisation
kubectl patch application playground-app -n argocd \
  -p '{"metadata": {"annotations": {"argocd.argoproj.io/refresh": "hard"}}}' \
  --type merge
```

## Nettoyage complet

```bash
# Arrêter tout
k3d cluster delete iot-bonus
docker stop gitlab-ce
docker rm gitlab-ce

# Nettoyer les données (optionnel)
rm -rf ~/gitlab-data
rm -f scripts/*_password.txt scripts/gitlab_token.txt
```

## Dépannage

### GitLab ne démarre pas

```bash
# Vérifier les logs
docker logs gitlab-ce

# Vérifier la mémoire
docker stats gitlab-ce

# GitLab nécessite au moins 4 GB RAM
```

### Argo CD ne peut pas accéder à GitLab

Problème: `host.docker.internal` ne fonctionne pas

Solution macOS:
```bash
# Dans application.yaml, remplacer par:
repoURL: http://host.docker.internal:8080/root/iot-deployment.git
```

Solution Linux:
```bash
# Utiliser l'IP de l'hôte
ip addr show docker0 | grep inet
# Utiliser cette IP dans repoURL
```

### Le pod ne démarre pas

```bash
# Vérifier les événements
kubectl get events -n dev --sort-by='.lastTimestamp'

# Vérifier les logs
kubectl logs -n dev <pod-name>

# Vérifier la description
kubectl describe pod -n dev <pod-name>
```

## Notes importantes

- GitLab tourne en Docker, pas dans Kubernetes (pour simplifier)
- Le namespace `gitlab` est créé mais peut être utilisé pour d'autres ressources GitLab si besoin
- `host.docker.internal` permet à K3d (qui tourne dans Docker) d'accéder à GitLab (aussi dans Docker)
- Les données GitLab sont persistées dans `~/gitlab-data`
- Le token GitLab n'expire jamais (pour l'exercice, pas recommandé en production)

## Validation du bonus

Pour que le bonus soit validé, il faut démontrer:

1. ✅ GitLab tourne localement
2. ✅ Le namespace `gitlab` existe
3. ✅ Argo CD est configuré avec GitLab (pas GitHub)
4. ✅ L'application se déploie depuis GitLab
5. ✅ Le changement de version (v1 → v2) fonctionne
6. ✅ Argo CD synchronise automatiquement

## Auteur

- Login: luqman
- Projet: Inception-of-Things (IoT) - Bonus
- École: 42 Luxembourg

### Repare 
# 1. Nettoyer complètement
k3d cluster delete iot-bonus
pkill -f "port-forward" 2>/dev/null || true
docker system prune -f

# 2. Attendre 5 secondes
sleep 5

# 3. Recréer le cluster
./scripts/02_setup_k3d.sh

# 4. Attendre que tout soit prêt (1-2 minutes)

# 5. Vérifier que tout fonctionne
kubectl get nodes
kubectl get pods -n argocd

# 6. Une fois que tous les pods Argo CD sont "Running", relancer
./scripts/04_setup_argocd.sh

# Guide de Démonstration - Bonus IoT

Ce guide vous aide à préparer et présenter le bonus lors de votre défense.

## ⏱️ Temps estimé de la démonstration: 15 minutes

---

## 📝 Checklist avant la défense

### Préparation (à faire AVANT la défense)

- [ ] GitLab est démarré et accessible: http://localhost:8080
- [ ] Cluster K3d est créé: `k3d cluster list | grep iot-bonus`
- [ ] Argo CD est accessible: http://localhost:8090
- [ ] Application tourne en v1: `curl http://localhost:8888`
- [ ] Tous les tests passent: `./scripts/test.sh`
- [ ] Git est configuré dans `confs/` avec remote GitLab
- [ ] Navigateur ouvert sur GitLab et Argo CD (2 onglets)

---

## 🎬 Scénario de démonstration

### 1️⃣ Introduction (2 min)

**Expliquer l'architecture:**

```
"J'ai mis en place GitLab localement dans Docker, 
et configuré Argo CD pour déployer automatiquement 
depuis ce GitLab local au lieu de GitHub."
```

**Montrer la structure:**

```bash
cd bonus
tree -L 2
```

**Points clés à mentionner:**
- GitLab dans Docker (pas dans K8s pour simplifier)
- Namespace `gitlab` créé (même si vide)
- CI/CD complet avec synchronisation automatique

---

### 2️⃣ Démonstration de GitLab (3 min)

**Ouvrir GitLab:** http://localhost:8080

```bash
# Montrer les identifiants
cat scripts/gitlab_root_password.txt
```

**Se connecter et naviguer:**
1. Login avec `root` / mot_de_passe
2. Aller sur le projet: `root/iot-deployment`
3. Montrer le fichier `deployment.yaml`
4. Montrer qu'il y a la version `v1`:
   ```yaml
   image: wil42/playground:v1
   ```

---

### 3️⃣ Démonstration d'Argo CD (3 min)

**Ouvrir Argo CD:** http://localhost:8090

```bash
# Montrer les identifiants
cat scripts/argocd_password.txt
```

**Se connecter et naviguer:**
1. Login avec `admin` / mot_de_passe
2. Cliquer sur l'application `playground-app`
3. Montrer que:
   - Source: GitLab local (`http://host.docker.internal:8080/root/iot-deployment.git`)
   - Status: `Synced` et `Healthy`
   - Namespace: `dev`
   - Image actuelle: `wil42/playground:v1`

---

### 4️⃣ Vérification des namespaces (1 min)

```bash
# Montrer tous les namespaces
kubectl get namespace

# Doit afficher:
# argocd    Active
# gitlab    Active
# dev       Active
```

```bash
# Montrer les pods dans dev
kubectl get pods -n dev

# Doit afficher un pod playground-app en Running
```

---

### 5️⃣ Test de l'application (1 min)

```bash
# Tester que l'app répond
curl http://localhost:8888
```

**Résultat attendu:**
```json
{"status":"ok", "message": "v1"}
```

**Aussi possible dans le navigateur:** http://localhost:8888

---

### 6️⃣ Démonstration du CI/CD (5 min) ⭐ **PARTIE CRITIQUE**

**C'est ici qu'on prouve que tout fonctionne!**

#### Étape 1: Modifier le code

```bash
cd confs/

# Changer v1 en v2
sed -i '' 's/playground:v1/playground:v2/g' deployment.yaml

# Vérifier le changement
cat deployment.yaml | grep image
# Doit afficher: image: wil42/playground:v2
```

#### Étape 2: Pousser vers GitLab

```bash
# Commit et push
git add deployment.yaml
git commit -m "Update to version v2"
git push origin main
```

**Credentials si demandés:**
- Username: `root`
- Password: (le mot de passe root GitLab)

#### Étape 3: Montrer la synchronisation dans GitLab

**Retour sur GitLab (navigateur):**
1. Rafraîchir la page du projet
2. Cliquer sur `deployment.yaml`
3. Montrer que le fichier contient maintenant `v2`

#### Étape 4: Montrer la synchronisation dans Argo CD

**Retour sur Argo CD (navigateur):**
1. Rafraîchir la page de l'application
2. Observer que:
   - L'application passe à `OutOfSync` (quelques secondes)
   - Puis Argo CD détecte le changement
   - Auto-sync se déclenche
   - L'application revient à `Synced`
   - L'image affichée est maintenant `wil42/playground:v2`

**Si nécessaire, forcer la synchronisation:**
```bash
# Forcer un refresh
kubectl patch application playground-app -n argocd \
  -p '{"metadata": {"annotations": {"argocd.argoproj.io/refresh": "hard"}}}' \
  --type merge
```

#### Étape 5: Vérifier le nouveau pod

```bash
# Voir que le pod a été recréé
kubectl get pods -n dev

# Vérifier l'image du nouveau pod
kubectl describe pod -n dev $(kubectl get pods -n dev -o name | grep playground) | grep Image:

# Doit afficher: Image: wil42/playground:v2
```

#### Étape 6: Tester la nouvelle version

```bash
# Test avec curl
curl http://localhost:8888
```

**Résultat attendu:**
```json
{"status":"ok", "message": "v2"}
```

**✅ La version a changé automatiquement grâce au CI/CD!**

---

## 🎯 Points importants à mentionner

### Différences avec la Partie 3

| Aspect | Partie 3 | Bonus |
|--------|----------|-------|
| Git | GitHub | **GitLab local** |
| GitLab namespace | ❌ | **✅ Créé** |
| Infrastructure | Cloud | **Tout en local** |
| Complexité | Moyenne | **Plus élevée** |

### Avantages du setup local

- **Autonomie complète:** Pas besoin d'internet pour le CI/CD
- **Confidentialité:** Le code reste local
- **Rapidité:** Pas de latence réseau
- **Apprentissage:** Comprendre l'architecture complète

---

## 🐛 Problèmes courants et solutions

### Le push vers GitLab échoue

**Erreur:** `fatal: Authentication failed`

**Solution:**
```bash
# Vérifier l'URL remote
git remote -v

# Doit être: http://localhost:8080/root/iot-deployment.git
# Si incorrect:
git remote set-url origin http://localhost:8080/root/iot-deployment.git
```

### Argo CD ne se synchronise pas

**Solution 1:** Vérifier le repository secret
```bash
kubectl get secret gitlab-repo -n argocd -o yaml
```

**Solution 2:** Forcer la synchronisation
```bash
kubectl patch application playground-app -n argocd \
  -p '{"metadata": {"annotations": {"argocd.argoproj.io/refresh": "hard"}}}' \
  --type merge
```

### Le pod reste en Pending

**Solution:**
```bash
# Voir pourquoi
kubectl describe pod -n dev <pod-name>

# Souvent: pas assez de ressources
# Augmenter la RAM de Docker Desktop (6-8 GB)
```

### host.docker.internal ne fonctionne pas

**Sur Linux:**
```bash
# Utiliser l'IP de l'hôte à la place
ip addr show docker0 | grep inet

# Puis modifier application.yaml avec cette IP
```

---

## 📊 Commandes de vérification rapide

```bash
# Tout vérifier en une commande
./scripts/test.sh

# Status complet
kubectl get all -n argocd
kubectl get all -n dev
kubectl get all -n gitlab
docker ps | grep gitlab
```

---

## 🎓 Questions attendues des évaluateurs

### Q: Pourquoi GitLab est dans Docker et pas dans K8s?

**R:** Pour simplifier. GitLab dans K8s nécessite Helm et beaucoup de ressources (8+ GB RAM). Le but du bonus est de démontrer l'intégration CI/CD, pas de deployer GitLab en production.

### Q: À quoi sert le namespace `gitlab` s'il est vide?

**R:** Il est créé pour respecter les consignes du sujet ("Create a dedicated namespace named gitlab"). On pourrait y déployer des ressources GitLab supplémentaires (runners, registry) si on voulait aller plus loin.

### Q: Comment Argo CD accède à GitLab?

**R:** Via `host.docker.internal:8080` qui permet à un container Docker (K3d) d'accéder à un autre container (GitLab) sur l'hôte. C'est comme `localhost` mais depuis l'intérieur d'un container.

### Q: Quel est l'intérêt du token GitLab?

**R:** C'est l'authentification pour qu'Argo CD puisse lire le repository GitLab. Sans ce token, Argo CD ne pourrait pas accéder au code.

### Q: Comment fonctionne l'auto-sync?

**R:** Argo CD poll le repository GitLab toutes les 3 minutes par défaut. Quand il détecte un changement, il applique automatiquement les nouvelles configurations dans le cluster grâce à `syncPolicy.automated`.

---

## ✅ Validation finale

Avant de dire "c'est bon", vérifier:

- [ ] GitLab accessible et montre le projet
- [ ] Argo CD accessible et montre l'application synced
- [ ] Les 3 namespaces existent: `argocd`, `gitlab`, `dev`
- [ ] L'application répond sur le port 8888
- [ ] Le changement v1→v2 fonctionne de bout en bout
- [ ] Les évaluateurs peuvent voir les 2 versions dans GitLab (historique git)
- [ ] L'historique Argo CD montre les syncs

**Commande ultime:**
```bash
echo "=== Status GitLab ===" && docker ps | grep gitlab && \
echo "=== Status K3d ===" && k3d cluster list && \
echo "=== Namespaces ===" && kubectl get ns | grep -E 'argocd|gitlab|dev' && \
echo "=== Application ===" && curl -s http://localhost:8888
```

---

## 🚀 Bonne défense!

**Conseil final:** Restez calme, expliquez clairement chaque étape, et montrez que vous comprenez l'architecture complète du CI/CD.
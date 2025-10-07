# Inception-of-Things - Part 2: K3s and three simple applications

## Description
Déploiement de 3 applications web sur un cluster K3s avec routage Ingress basé sur le HOST.

### Architecture
- **1 VM** : Serveur K3s
- **3 applications** :
  - **app1** : 1 réplica, accessible via `app1.com`
  - **app2** : 3 réplicas, accessible via `app2.com`
  - **app3** : 1 réplica, route par défaut
- **Ingress Controller** : Traefik (inclus dans K3s)

## Prérequis

### Logiciels nécessaires

1. **Vagrant** (version 2.4.9 ou supérieure)
2. **Parallels Desktop** (version compatible ARM)
3. **Plugin Vagrant Parallels**
   ```bash
   vagrant plugin install vagrant-parallels
   ```

### Configuration système
- **OS** : macOS avec processeur Apple Silicon (ARM64)
- **RAM disponible** : Minimum 2 GB
- **Espace disque** : Minimum 10 GB

## Structure du projet

```
p2/
├── Vagrantfile
├── scripts/
│   └── setup.sh
├── confs/
│   ├── app1-deployment.yaml
│   ├── app2-deployment.yaml
│   ├── app3-deployment.yaml
│   └── ingress.yaml
└── README.md
```

## Contenu des fichiers

### Vagrantfile
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "luqmanS" do |srv|
    srv.vm.hostname = "luqmanS"
    srv.vm.network "private_network", ip: "192.168.56.110", netmask: "255.255.255.0"
    srv.vm.provider "parallels" do |prl|
      prl.name   = "luqmanS"
      prl.memory = 2048
      prl.cpus   = 2
    end
    srv.vm.provision "shell", path: "scripts/setup.sh"
  end
end
```

### scripts/setup.sh
Script d'installation automatique de K3s et déploiement des applications.

### confs/
Contient les manifestes Kubernetes pour les 3 applications et l'Ingress.

## Installation et lancement

### Étape 1 : Cloner le projet
```bash
cd Inception-of-Things/p2
```

### Étape 2 : Vérifier la structure des fichiers
```bash
# Vérifier que tous les fichiers existent
ls -la
ls scripts/
ls confs/

# Vérifier les permissions
chmod +x scripts/setup.sh
```

################
################
# Voir les boxes installées
vagrant box list

# Supprimer la box corrompue
vagrant box remove bento/ubuntu-22.04

# Relancer (va retélécharger automatiquement)
vagrant up

###############
###############

### Étape 3 : Lancer la VM
```bash
vagrant up
```

**Cette commande va :**
1. Créer la VM Ubuntu 22.04
2. Configurer le réseau (192.168.56.110)
3. Installer K3s en mode serveur
4. Déployer les 3 applications
5. Configurer l'Ingress

**Durée estimée** : 3-5 minutes

### Étape 4 : Configurer /etc/hosts
Pour accéder aux applications via les noms de domaine, modifiez votre fichier hosts :

```bash
sudo nano /etc/hosts
```

Ajoutez ces lignes à la fin :
```
192.168.56.110 app1.com
192.168.56.110 app2.com
```

Sauvegardez avec **Ctrl+O**, **Enter**, puis **Ctrl+X**.

## Vérifications

### Vérifier que la VM est démarrée
```bash
vagrant status
```

Résultat attendu :
```
Current machine states:
luqmanS                   running (parallels)
```

### Vérifier les pods
```bash
vagrant ssh luqmanS -c "sudo kubectl get pods"
```

Résultat attendu (tous les pods en `Running`) :
```
NAME                    READY   STATUS    RESTARTS   AGE
app1-576bd7f495-xxxxx   1/1     Running   0          2m
app2-58d8f7c4c8-xxxxx   1/1     Running   0          2m
app2-58d8f7c4c8-xxxxx   1/1     Running   0          2m
app2-58d8f7c4c8-xxxxx   1/1     Running   0          2m
app3-89469575c-xxxxx    1/1     Running   0          2m
```

**Note importante** : app2 doit avoir **3 pods** (3 réplicas).

### Vérifier les services
```bash
vagrant ssh luqmanS -c "sudo kubectl get svc"
```

Résultat attendu :
```
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
app1-service    ClusterIP   10.43.x.x       <none>        80/TCP    2m
app2-service    ClusterIP   10.43.x.x       <none>        80/TCP    2m
app3-service    ClusterIP   10.43.x.x       <none>        80/TCP    2m
kubernetes      ClusterIP   10.43.0.1       <none>        443/TCP   3m
```

### Vérifier l'Ingress
```bash
vagrant ssh luqmanS -c "sudo kubectl get ingress"
```

Résultat attendu :
```
NAME           CLASS    HOSTS               ADDRESS          PORTS   AGE
app-ingress    <none>   app1.com,app2.com   192.168.56.110   80      2m
```

### Vérifier les réplicas de app2
```bash
vagrant ssh luqmanS -c "sudo kubectl get deployment app2"
```

Résultat attendu :
```
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
app2   3/3     3            3           2m
```

**Important** : READY doit afficher **3/3**.

## Tests fonctionnels

### Test avec curl

```bash
# Test app1 (fond violet)
curl http://app1.com

# Test app2 (fond rose, 3 réplicas)
curl http://app2.com

# Test app3 (fond bleu, route par défaut)
curl http://192.168.56.110
```

Chaque commande doit retourner du HTML complet avec :
- app1 : "🚀 Application 1"
- app2 : "⚡ Application 2" avec "Replicas: 3"
- app3 : "🌟 Application 3" avec "Default fallback"

### Test dans le navigateur

Ouvrez dans votre navigateur :
- http://app1.com (page violette)
- http://app2.com (page rose)
- http://192.168.56.110 (page bleue)

Vous devriez voir 3 pages différentes avec des dégradés de couleurs.

### Test du load balancing (app2 avec 3 réplicas)

```bash
# Vérifier les 3 pods de app2
vagrant ssh luqmanS -c "sudo kubectl get pods -l app=app2 -o wide"
```

Les 3 pods doivent être en état `Running`.

## Commandes utiles

### Gérer la VM

```bash
# Arrêter la VM
vagrant halt

# Redémarrer la VM
vagrant reload

# Se connecter en SSH
vagrant ssh luqmanS

# Détruire la VM
vagrant destroy -f
```

### Commandes Kubernetes

```bash
# Voir tous les pods
vagrant ssh luqmanS -c "sudo kubectl get pods -A"

# Voir les logs d'un pod
vagrant ssh luqmanS -c "sudo kubectl logs <pod-name>"

# Voir les détails de l'Ingress
vagrant ssh luqmanS -c "sudo kubectl describe ingress app-ingress"

# Redéployer les applications
vagrant ssh luqmanS -c "sudo kubectl delete -f /vagrant/confs/"
vagrant ssh luqmanS -c "sudo kubectl apply -f /vagrant/confs/"
```

## Configuration réseau

- **VM IP** : 192.168.56.110
- **Réseau** : Private network (host-only)
- **Ports** : 
  - 80 (HTTP via Ingress)
  - 22 (SSH)

## Fonctionnement technique

### Déploiement automatique

Le script `setup.sh` effectue les opérations suivantes :
1. Installation de K3s avec Traefik (Ingress Controller intégré)
2. Attente que K3s soit complètement démarré
3. Application des manifestes Kubernetes :
   - Deployments (app1, app2, app3)
   - ConfigMaps (contenu HTML personnalisé)
   - Services (ClusterIP)
   - Ingress (routage basé sur HOST)

### Routage Ingress

L'Ingress utilise les règles suivantes :
- **Host: app1.com** → app1-service
- **Host: app2.com** → app2-service
- **Default (aucun host ou autre)** → app3-service

### Applications

Chaque application utilise :
- **Image** : nginx:alpine (légère)
- **ConfigMap** : HTML personnalisé monté dans `/usr/share/nginx/html`
- **Service** : ClusterIP sur le port 80

## Dépannage

### Problème : Les pods ne démarrent pas

```bash
# Vérifier les événements
vagrant ssh luqmanS -c "sudo kubectl get events --sort-by='.lastTimestamp'"

# Vérifier les logs du pod
vagrant ssh luqmanS -c "sudo kubectl logs <pod-name>"

# Vérifier les ressources
vagrant ssh luqmanS -c "sudo kubectl describe pod <pod-name>"
```

### Problème : Impossible d'accéder aux applications

```bash
# Vérifier que l'IP est bien configurée
vagrant ssh luqmanS -c "ip a"

# Vérifier /etc/hosts sur votre Mac
cat /etc/hosts | grep 192.168.56.110

# Tester directement avec l'IP
curl http://192.168.56.110

# Tester avec le header Host
curl -H "Host: app1.com" http://192.168.56.110
```

### Problème : L'Ingress ne fonctionne pas

```bash
# Vérifier l'état de Traefik
vagrant ssh luqmanS -c "sudo kubectl get pods -n kube-system | grep traefik"

# Vérifier les logs de Traefik
vagrant ssh luqmanS -c "sudo kubectl logs -n kube-system -l app.kubernetes.io/name=traefik"

# Vérifier la configuration de l'Ingress
vagrant ssh luqmanS -c "sudo kubectl describe ingress app-ingress"
```

### Problème : app2 n'a pas 3 réplicas

```bash
# Vérifier le deployment
vagrant ssh luqmanS -c "sudo kubectl describe deployment app2"

# Forcer le scaling
vagrant ssh luqmanS -c "sudo kubectl scale deployment app2 --replicas=3"
```

## Notes importantes

- Les ConfigMaps contiennent le HTML complet de chaque application
- Traefik est l'Ingress Controller par défaut de K3s (aucune installation supplémentaire nécessaire)
- Le dossier `/vagrant` est automatiquement partagé entre l'hôte et la VM
- Les 3 applications utilisent des couleurs différentes pour faciliter les tests

## Validation du projet

Pour valider que tout fonctionne correctement :

1. ✅ `vagrant status` montre la VM en état "running"
2. ✅ `kubectl get pods` montre 5 pods au total (1+3+1) tous en "Running"
3. ✅ `kubectl get ingress` montre l'Ingress avec les 2 hosts
4. ✅ `curl http://app1.com` retourne la page HTML de app1
5. ✅ `curl http://app2.com` retourne la page HTML de app2
6. ✅ `curl http://192.168.56.110` retourne la page HTML de app3
7. ✅ app2 a exactement 3 réplicas visibles avec `kubectl get pods -l app=app2`

## Auteur
- Login : luqman
- Projet : Inception-of-Things (IoT)
- École : 42

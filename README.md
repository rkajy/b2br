# b2br
BornToBeRoot project

Debian 12

Virtualbox 6.1

Le mot de passe root / user est Bn2br-2025! (conforme à la politique stricte Born2beroot).


| Paramètre                     | Valeur recommandée                                                         |
| ----------------------------- | -------------------------------------------------------------------------- |
| **Nom de la VM**              | born2beroot                                                                |
| **Type**                      | Linux                                                                      |
| **Version**                   | Debian (64-bit)                                                            |
| **Mémoire vive (RAM)**        | 1024 Mo ou 2048 Mo                                                         |
| **Processeurs**               | 1 ou 2 (activer PAE/NX dans "Processeur" > "Avancé")                       |
| **Disque dur virtuel**        | 40 Go (dynamique ou fixe)                                                  |
| **Contrôleur SATA**           | Attacher ISO générée comme lecteur optique principal                       |
| **Activer EFI**               | ❌ (Désactive EFI si tu n’as pas inclus une partition EFI dans preseed.cfg) |
| **Carte réseau**              | NAT ou Bridged (pour accès Internet pendant l’installation)                |
| **Périphérique de démarrage** | CD/DVD en premier                                                          |
| **Réseau**                    | NAT (ou Bridge si tu veux SSH depuis ta machine hôte)                      |


Pour copier de ma debian graphical a ma machine hote:

1_ j'ai lance ssh_config.sh dans la vm

2_ Dans network setting
ajouter une rege NAT
SSH TCP 127.0.0.1 ; Host port = 4242;  guest ip = la commande renvoye par la commande ip a; guest port = 4242

scp -P 4242 radandri@127.0.0.1:/home/radandri/b2br/debian-preseeded.iso .


# Born2beroot – Projet 42

Ce projet consiste à sécuriser une machine virtuelle Debian 11 ou 12 en respectant des règles de cybersécurité : configuration système, gestion des utilisateurs, pare-feu, monitoring, etc.

## 🖥️ Configuration de la VM

- **Nom de la machine (hostname)** : `debian42`
- **Utilisateur principal** : `radandri42`
- **Mot de passe** : `password42`
- **Accès root SSH** : Interdit
- **Port SSH** : `4242`
- **UFW (pare-feu)** : Activé, port 4242 autorisé
- **Partition disque** : LVM + chiffrement (LUKS)
- **AppArmor** : Activé

## 🔐 Sécurité

- **Politique de mot de passe** :  
  - Longueur min : 10 caractères  
  - Au moins 1 majuscule, 1 minuscule, 1 chiffre  
  - Pas plus de 3 répétitions  
  - 7 différences avec l'ancien mot de passe  
- **Expiration des mots de passe** :  
  - Tous les 30 jours  
  - Avertissement 7 jours avant expiration

## 👥 Groupes utilisateurs

- `radandri42` appartient à : `sudo`, `user42`
- `user42` est un groupe personnalisé

## ⚠️ Sudo

- Le fichier `/etc/sudoers` inclut :
  - `Defaults logfile="/var/log/sudo"`
- Tous les accès sudo sont journalisés.

## 📊 Monitoring

- Script : `/usr/local/bin/monitoring.sh`
- Affiche automatiquement les infos système à chaque redémarrage via `cron`
- Infos affichées :
  - Architecture système
  - Nombre de CPU / vCPU
  - RAM utilisée / totale
  - Utilisation disque
  - Charge CPU
  - Date du dernier boot
  - Utilisation LVM
  - Connexions TCP établies
  - Nombre d'utilisateurs connectés
  - Adresse IP et MAC
  - Nombre de commandes `sudo` exécutées

## ⚙️ Services au boot

- AppArmor : actif
- Monitoring via cron (`@reboot`)
- SSH : activé (port 4242)

## 📁 Script utilisé

Script post-installation disponible ici :  
📎 [`post_install.sh`](https://github.com/rkajy/b2br/blob/main/post_install.sh)

Il est automatiquement lancé à la fin de l’installation via le fichier `preseed.cfg`.


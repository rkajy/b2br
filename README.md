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


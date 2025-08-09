#!/bin/bash

set -e


    ### === SSH === ###
    echo "[8/10] Gestion du SSH..."

    echo "Configuration de SSH..."
    #create a backup before updating file
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    #change Port 22 to Port 4242
    #set PermitRootLogin to no
    #don't forget to uncomment both lines after making changes
    sudo sed -i 's/#Port 22/Port 4242/' /etc/ssh/sshd_config
    sudo sed -i 's/Port 22/Port 4242/' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo systemctl enable ssh
    sudo systemctl restart ssh # once done, restart SSH server
    echo "SSH configuré sur le port 4242 (root interdit)"

    #echo "Don't forget to add in Network setting on virtualbox a rule SSH with : protocole: TCP, Host port: 4242, Guest port: 4242"

#echo "To connect with ssh, type : ssh radandri42@127.0.0.1 -p 4242"

#echo "To copy file type for example : scp -P 2222 born2beroot.sh radandri42@127.0.0.1:/home/radandri42/"
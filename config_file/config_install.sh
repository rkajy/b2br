#!/bin/bash

WORKDIR="$(pwd)"
CONFIG_DIR="$WORKDIR"
USER_HOME="/home/radandri"
USERNAME=$(whoami)

cp "$CONFIG_DIR/newsudorule" "/etc/sudoers.d/newsudorule"
chmod 440 /etc/sudoers.d/newsudorule

visudo -c -f /etc/sudoers.d/newsudorule

# Fonction de remplacement sécurisé
replace_file() {
    local src="$1"   # Fichier .expected sur l'ISO
    local dest="$2"  # Fichier de destination dans le système

    if [ -f "$src" ]; then
        if [ -f "$dest" ]; then
            echo "[INFO] Sauvegarde de $dest → ${dest}.backup"
            cp "$dest" "${dest}.backup"
        else
            echo "[WARN] $dest introuvable, pas de sauvegarde."
        fi

        echo "[INFO] Remplacement de $dest par $src"
        cp "$src" "$dest"
    else
        echo "[WARN] $src introuvable, remplacement ignoré."
    fi
}

# 1. /etc/login.defs
replace_file "$CONFIG_DIR/login.defs.expected" "/etc/login.defs"
chmod 644 /etc/login.defs

# 2. /etc/ssh/sshd_config
replace_file "$CONFIG_DIR/sshd_config.expected" "/etc/ssh/sshd_config"
chmod 600 /etc/ssh/sshd_config

# 3. /etc/pam.d/common-password
replace_file "$CONFIG_DIR/common-password.expected" "/etc/pam.d/common-password"
chmod 644 /etc/pam.d/common-password


echo "Configuration du pare-feu UFW..."
#change age => chage, use to manage user password expiry and account aging information.
# -M : set maximum number of days before password change to MAX_DAYS
# -m : set minimum number of days before password change to MIN_DAYS
# -W : set expiration warning days to WARN_DAYS
chage -M 30 -m 2 -W 7 "$USERNAME" #the password has to expire every 30 days, the minimum number of days allowed before the modification of a password will be set to 2
                                  #the user has to receive a warning message 7 days before their password expires
chage -M 30 -m 2 -W 7 root


echo "Configuration du pare-feu UFW..."
ufw --force enable #enable the firewall
ufw allow 4242 #allow incoming trafic on port 4242
#ufw default deny incoming #blocks all incoming requests
#ufw default allow outgoing #allows all outgoing requests
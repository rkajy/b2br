#!/bin/bash


CONFIG_DIR="/cdrom/config_file"
USER_HOME="/home/radandri"
CONFIG_DIR="/cdrom/config_file"

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

# Configuration de l’expiration des mots de passe
systemctl enable ssh
systemctl restart ssh # once done, restart SSH server

USERNAME="radandri"
HOSTNAME="radandri42"

#create a group called user42
addgroup user42
adduser radandri sudo #add sudo group to radandri users
adduser radandri user42

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

### === PARAMÈTRES === ###
MONITOR_SCRIPT="$HOME/monitoring.sh"

echo "Déploiement du script monitoring.sh..."
# The architecture of your operating system and its kernel version
# The number of physical processors
# The number of virtual processors
# The current available RAM on your server and its utilisation rate as a percentage
# The current available storage on your server and its utilization rate as a percentage
# The current utilisation rate of your processors as a percentage
# The date and time of the last reboot
# Whether LVM is active or not
# The number of active connections
# The number of users using the server
# The IPv4 adress of your server and its MAC (Media Access Control) adress
# The number of commands executed with the sudo program
cat << 'EOF' > "$MONITOR_SCRIPT"
#!/bin/bash
ARCH=$(uname -a)
PCPU=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
VCPU=$(grep -c ^processor /proc/cpuinfo)
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_PERC=$(free | awk '/Mem:/ {printf("%.2f"), $3/$2 * 100}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PERC=$(df / | awk 'NR==2 {printf("%.0f"), $3/$2 * 100}')
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
LAST_BOOT=$(who -b | awk '{print $3 " " $4}')
LVM=$(lsblk | grep -q "lvm" && echo "yes" || echo "no")
TCP_CONN=$(ss -ta | grep ESTAB | wc -l)
LOGGED_USERS=$(users | wc -w)
IPV4=$(hostname -I | awk '{print $1}')
MAC=$(ip link show | awk '/ether/ {print $2}' | head -n 1)
SUDO_CMDS=$(journalctl _COMM=sudo | grep COMMAND | wc -l)

wall << EOM
#Architecture: $ARCH
#CPU physical : $PCPU
#vCPU : $VCPU
#Memory Usage: $RAM_USED/${RAM_TOTAL}MB (${RAM_PERC}%)
#Disk Usage: $DISK_USED/${DISK_TOTAL} (${DISK_PERC}%)
#CPU load: $CPU_LOAD
#Last boot: $LAST_BOOT
#LVM use: $LVM
#Connections TCP : $TCP_CONN ESTABLISHED
#User log: $LOGGED_USERS
#Network: IP $IPV4 ($MAC)
#Sudo : $SUDO_CMDS cmd
EOM
EOF
#wall : write a message to all users
chmod +x "$MONITOR_SCRIPT"
#Add cron and run it when the system reboot
(crontab -l 2>/dev/null | grep -v "$MONITOR_SCRIPT" ; echo "*/10 * * * * $MONITOR_SCRIPT") | crontab -

echo "Installation done !"

# Copier post_install.sh dans home
cp /cdrom/post_install.sh "$USER_HOME/"

# Copier monitoring.sh dans home
cp /cdrom/monitoring.sh "$USER_HOME/"

# Copier tous les fichiers de config dans un dossier dédié dans home
mkdir -p "$USER_HOME/config_file"
cp -r "$CONFIG_DIR/"* "$USER_HOME/config_file/"

# Ajuster la propriété à l'utilisateur (important !)
chown -R radandri:radandri "$USER_HOME/post_install.sh" "$USER_HOME/monitoring.sh" "$USER_HOME/config_file"
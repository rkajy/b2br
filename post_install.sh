# REQUIREMENTS:
# Download the LTS (Latest Stable Version) version of debian
# Create at least 2 encrypted partitions using LVM
# Why I choose Debian ?
# Differences betwen aptitude and apt
# What SELinux or AppArmor is ?
# SSH service will be running on the mandatory port 4242
# It must not possible to connect using SSH as root because of security reasons
# Configure firewall UFW and thus leave only port 4242 open in your virtual machine, it must be active when you launch your virtual machine
# Be able to modify the hostname 
# Implement a strong password policy, what chage command is ?
# Install and configure sudo following strict rules
# In addition to the root user, a user with your login as username has to be present
# This user has to belong to the user42 and sudo group
# To be able to create a new user and assign it to a group

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

USERNAME="radandri"
HOSTNAME="radandri42"
GROUPNAME="radandri42"


echo "[2/10] Attribution des groupes..."
sudo groupadd -f "$GROUPNAME"
sudo usermod -aG sudo "$USERNAME"
sudo usermod -aG "$GROUPNAME" "$USERNAME"

echo "[3/10] Configuration du hostname..."
if [ "$(hostname)" != "$HOSTNAME" ]; then
  sudo cp /etc/hostname /etc/hostname.backup
  sudo echo "$HOSTNAME" > /etc/hostname
  sudo hostnamectl set-hostname "$HOSTNAME"
  echo "Hostname mis à jour."
else
  echo "Hostname déjà correct."
fi

echo "[1/10] Politique de mot de passe (PAM + chage)..."
sudo cp /etc/pam.d/common-password /etc/pam.d/common-password.backup
grep -q "pam_pwquality.so" /etc/pam.d/common-password || {
  sudo echo "password requisite pam_pwquality.so retry=3 minlen=10 ucredit=-1 lcredit=-1 dcredit=-1 maxrepeat=3 reject_username difok=7 enforce_for_root" >> /etc/pam.d/common-password
}
#change age => chage, use to manage user password expiry and account aging information.
# -M : set maximum number of days before password change to MAX_DAYS
# -m : set minimum number of days before password change to MIN_DAYS
# -W : set expiration warning days to WARN_DAYS
sudo chage -M 30 -m 2 -W 7 "$USERNAME" #the password has to expire every 30 days, the minimum number of days allowed before the modification of a password will be set to 2
                                  #the user has to receive a warning message 7 days before their password expires
sudo chage -M 30 -m 2 -W 7 root

### === PARAMÈTRES === ###
SUDO_LOG_DIR="/var/log/sudo"

echo "[5/10] Configuration sudo sécurisée..."
sudo mkdir -p "$SUDO_LOG_DIR"
sudo chmod 700 "$SUDO_LOG_DIR"
sudo touch /etc/sudoers.d/42sudo
echo "$USERNAME ALL=(ALL:ALL) ALL" > /etc/sudoers.d/42sudo
sudo cp /etc/sudoers /etc/sudoers.backup
sudo grep -q "Defaults logfile=" /etc/sudoers || echo "Defaults logfile=\"$SUDO_LOG_DIR/sudo.log\"" >> /etc/sudoers
sudo grep -q 'Defaults log_input' /etc/sudoers || echo 'Defaults log_input' >> /etc/sudoers
sudo grep -q 'Defaults log_output' /etc/sudoers || echo 'Defaults log_output' >> /etc/sudoers
sudo grep -q 'Defaults iolog_dir=' /etc/sudoers || echo 'Defaults iolog_dir="/var/log/sudo"' >> /etc/sudoers
sudo grep -q "Defaults badpass_message=" /etc/sudoers || echo "Defaults badpass_message=\"Wrong password... Access Denied.\"" >> /etc/sudoers
sudo grep -q "Defaults passwd_tries=" /etc/sudoers || echo "Defaults passwd_tries=3" >> /etc/sudoers
sudo grep -q "Defaults requiretty" /etc/sudoers || echo "Defaults requiretty" >> /etc/sudoers
sudo grep -q "Defaults secure_path=" /etc/sudoers || echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"' >> /etc/sudoers

echo "[6/10] AppArmor (sécurité)..."
sudo systemctl enable apparmor
sudo systemctl start apparmor

echo "[7/10] Configuration du pare-feu UFW..."
sudo apt install -y ufw #install the firewall
sudo ufw default deny incoming #blocks all incoming requests
sudo ufw default allow outgoing #allows all outgoing requests
sudo ufw allow 4242/tcp #allow incoming trafic on port 4242
sudo ufw --force enable #enable the firewall




### === PARAMÈTRES === ###
MONITOR_SCRIPT="/usr/local/bin/monitoring.sh"

echo "[9/10] Déploiement du script monitoring.sh..."
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
(crontab -l 2>/dev/null | grep -v "$MONITOR_SCRIPT" ; echo "*/10 * * * * $MONITOR_SCRIPT") | crontab -

echo "Installation done !"

echo "Don't forget to add in Network setting on virtualbox a rule SSH with : protocole: TCP, Host port: 2222, Guest port: 4242"

echo "To connect with ssh, type : ssh radandri42@127.0.0.1 -p 2222"

echo "To copy file type for example : scp -P 2222 born2beroot.sh radandri42@127.0.0.1:/home/radandri42/"

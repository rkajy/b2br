#!/bin/bash

set -e

#Install the requirements
apt install -y sudo ufw openssh-server libpam-pwquality

#echo "127.0.1.1     radandri" >> etc/hosts
#hostnamectl set-hostname $HOSTNAME


### === SSH === ###
echo "[8/10] Gestion du SSH..."
echo "Configuration de SSH..."
#create a backup before updating file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
cp /etc/ssh/ssh_config /etc/ssh/ssh_config.backup
#change Port 22 to Port 4242
#set PermitRootLogin to no
#don't forget to uncomment both lines after making changes
sed -i 's/#Port 22/Port 4242/' /etc/ssh/ssh_config
sed -i 's/Port 22/Port 4242/' /etc/ssh/ssh_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl enable ssh
systemctl restart ssh # once done, restart SSH server
echo "SSH configuré sur le port 4242 (root interdit)"

USERNAME="radandri"
HOSTNAME="radandri42"
GROUPNAME="radandri42"

#create a group called user42
addgroup user42
adduser radandri sudo #add sudo group to radandri users
adduser radandri user42

# echo "[2/10] Attribution des groupes..."
# groupadd -f "$GROUPNAME" #create a group if needed
# usermod -aG sudo "$USERNAME" #assign username to sudo group
# usermod -aG "$GROUPNAME" "$USERNAME"
# usermod -aG "$USERNAME" "$GROUPNAME"

#change age => chage, use to manage user password expiry and account aging information.
# -M : set maximum number of days before password change to MAX_DAYS
# -m : set minimum number of days before password change to MIN_DAYS
# -W : set expiration warning days to WARN_DAYS
#chage -M 30 -m 2 -W 7 "$USERNAME" #the password has to expire every 30 days, the minimum number of days allowed before the modification of a password will be set to 2
                                  #the user has to receive a warning message 7 days before their password expires
#chage -M 30 -m 2 -W 7 root


echo "[7/10] Configuration du pare-feu UFW..."
ufw --force enable #enable the firewall
ufw allow 4242 #allow incoming trafic on port 4242
#ufw default deny incoming #blocks all incoming requests
#ufw default allow outgoing #allows all outgoing requests

touch /etc/sudoers.d/sudo_config
mkdir -p /var/log/sudo

cat << 'EOF' > /etc/sudoers.d/sudo_config
Defaults  passwd_tries=3
Defaults  badpass_message="Message d'erreur personnalisee"
Defaults  logfile="/var/log/sudo/sudo_config"
Defaults  log_input, log_output
Defaults  iolog_dir=/var/log/sudo"
Defaults  requiretty
Defaults  secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
EOF

cp /etc/login.defs /etc/login.defs.backup
sed -i 's/PASS_MAX_DAYS 99999/PASS_MAX_DAYS 30/' /etc/login.defs
sed -i 's/PASS_MIN_DAYS 0/PASS_MIN_DAYS 2/' /etc/login.defs
echo "[1/10] Politique de mot de passe (PAM + chage)..."
cp /etc/pam.d/common-password /etc/pam.d/common-password.backup
sed -i 's/pam-pwquality.so rety=3/pam-pwquality.so retry=3 minlen=10 ucredit=-1 dcredit=-1 lcredit=-1 maxrepeat=3 reject_username difok=7 enforce_for_root/' /etc/pam.d/common-password

### === PARAMÈTRES === ###
MONITOR_SCRIPT="$HOME/monitoring.sh"

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
#Add cron and run it when the system reboot
(crontab -l 2>/dev/null | grep -v "$MONITOR_SCRIPT" ; echo "*/10 * * * * $MONITOR_SCRIPT") | sudo crontab -

echo "Installation done !"

#echo "Don't forget to add in Network setting on virtualbox a rule SSH with : protocole: TCP, Host port: 2222, Guest port: 4242"

#echo "To connect with ssh, type : ssh radandri42@127.0.0.1 -p 2222"

#echo "To copy file type for example : scp -P 2222 born2beroot.sh radandri42@127.0.0.1:/home/radandri42/"

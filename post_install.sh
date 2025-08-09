#!/bin/bash

USER_HOME="/home/radandri"

USERNAME="radandri"
HOSTNAME="radandri42"

#create a group called user42
addgroup user42
adduser radandri sudo #add sudo group to radandri users
adduser radandri user42

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
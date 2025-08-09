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
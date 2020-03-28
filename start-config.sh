#!/bin/bash

######################
# Check sudo rights
######################
if [[ $EUID -ne 0 ]]; then
   echo "Dieses Script muss als root ausgefuert werden!" 1>&2
   exit 1
fi


######################
# Static IP config
######################
sed -i "/interface eth/d;/interface wlan/d;/static ip_address/d;/static routers/d;/static domain_name_servers/d;" /etc/dhcpcd.conf
sed -i -e "\$ainterface eth0" -e "\$astatic ip_address=192.168.24.104/24" -e "\$astatic routers=192.168.24.1" /etc/dhcpcd.conf

service dhcpcd restart
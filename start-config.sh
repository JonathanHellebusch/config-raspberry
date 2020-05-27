#!/bin/bash

# Check sudo rights
if [[ $EUID -ne 0 ]]; then
   echo "Dieses Script muss als root ausgefuert werden!" 1>&2
   exit 1
fi

#Netzwerkkonfiguration 
	# Static IP config
	echo "Alle voreingestellten Interfaces werden entfernt"
	sed -i "/interface eth/d;/interface wlan/d;/static ip_address/d;/static routers/d;/static domain_name_servers/d;" /etc/dhcpcd.conf

	echo "Statische IP wird eingerichtet"
	sed -i -e "\$ainterface eth0" -e "\$astatic ip_address=192.168.24.104/24" -e "\$astatic routers=192.168.24.1" /etc/dhcpcd.conf

	# Setup WLAN
	#echo "WLAN wird eingerichtet"
	#sed -i -e "\$ainterface wlan0" -e "\$astatic ip_address=192.168.24.166/24" -e "\$astatic routers=192.168.24.1" /etc/dhcpcd.conf
	#wpa_passphrase "SSID" "PASSWORT" >> /etc/wpa_supplicant/wpa_supplicant.conf

	#Restart Service
	echo "DHCPCD neustart"
	service dhcpcd restart

#Webserver
	# Install Apache
	dpkg -s apache2 &> /dev/null
	if [ $? -eq 0 ]; then
		echo "Apache ist schon installiert!"
	else
		echo "Apache wird installiert"
		apt install apache2 -y
	fi

	#Copy index.html
	echo "Homepage durch eigene Homepage ersetzen"
	\cp ./index.html /var/www/html
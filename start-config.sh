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
	systemctl restart dhcpcd

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

#Samba
	# Install Apache
	dpkg -s samba &> /dev/null
	if [ $? -eq 0 ]; then
		echo "Samba ist schon installiert!"
	else
		echo "Samba wird installiert"
		apt install samba -y
	fi

	#Configure Samba
	echo "Konfigurieren der Freigaben readonlyuser und readwriteuser"
	echo "
	[readonlyuser]
	comment = Readonly User
	path = /pi/samba/share
	browsable = yes
	guest ok = yes
	read only = yes
	create mask = 0444

	[readwriteuser]
	comment = Readonly User
	path = /pi/samba/share
	browsable = yes
	guest ok = no
	read only = no
	create mask = 0666
	" >> /etc/samba/smb.conf

	#Test Configuration
	echo "Test der Konfigurationsdatei"
	testparm /etc/samba/smb.conf -s

	#Restart Samba
	echo "Neustart des Samba-Service"
	systemctl restart smbd

#!/bin/bash
#Konfiguration-Raspberry
# Check sudo rights
if [[ $EUID -ne 0 ]]; then
   echo "Dieses Script muss als root ausgefuert werden!" 1>&2
   exit 1
fi

#update/upgrade
apt update
apt upgrade


wait_for_key()
{
	printf "\n"
	read -p "Drücke die AnyKey-Taste ..." -n1 -s
	printf "\n\n"
}

wait_for_key

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

wait_for_key

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
	find -maxdepth 4 -iname 'index.html' -exec cp {} /var/www/html/ \;

wait_for_key

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

wait_for_key

#Benutzer
	#Add User benutzer
	echo "Anlegen des Benutzers 'benutzer' mit dem Passwort 'raspberry'"
	useradd benutzer -g users
	passwd benutzer raspberry

	#Add User fernzugriff
	echo "Anlegen des Benutzers 'fernzugriff' mit dem Passwort 'raspberry' und sudo-Recht"
	useradd fernzugriff -G sudo
	passwd fernzugriff raspberry

wait_for_key

#SSH
	# Install OpenSSH-Server
	dpkg -s openssh-server &> /dev/null
	if [ $? -eq 0 ]; then
		echo "OpenSSH-Server ist schon installiert!"
	else
		echo "OpenSSH-Server wird installiert"
		apt install openssh-server -y
	fi

	echo "Benutzer 'fernzugriff' als einzigem den SSH-Zugang gewähren"
	echo "AllowUsers fernzugriff" >> /etc/ssh/sshd_config

	echo "Neustart des SSH-Service"
	systemctl restart ssh

wait_for_key

#Firewall
	#ICMP-Pakete werden verworfen
	echo "ICMP-Pakete werden verworfen"
	iptables -A INPUT -s 127.0.0.1 -p icmp -j DROP

	#Zugriff auf Webserver und Freigaben aus lokalen Netz erlaubt
	echo "Zugriff auf Webserver und Freigaben aus lokalen Netz erlaubt"
	iptables -A INPUT  -p tcp -m multiport --dports 21,80,443 -m state --state NEW,ESTABLISHED -s 192.168.24.0/24 -j ACCEPT
	iptables -A OUTPUT -p tcp -m multiport --sports 21,80,443 -m state --state ESTABLISHED -s 192.168.24.0/24 -j ACCEPT
	iptables -A INPUT  -p tcp -m multiport --dports 21,80,443 -m state --state NEW,ESTABLISHED -s  127.0.0.0/8 -j ACCEPT
	iptables -A OUTPUT -p tcp -m multiport --sports 21,80,443 -m state --state ESTABLISHED -s 127.0.0.0/8 -j ACCEPT
	iptables -A INPUT -p tcp --dport 80 -j DROP

	#Zugriff auf SSH aus allen Netzwerken erlaubt
	echo "Zugriff auf SSH aus allen Netzwerken erlaubt"
	iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

	#Zugriff vom Linux-Server auf DNS-Server erlaubt
	echo "Zugriff vom Linux-Server auf DNS-Server erlaubt"
	iptables -A OUTPUT -p udp -d 8.8.8.8 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT  -p udp -s 8.8.8.8 --sport 53 -m state --state ESTABLISHED     -j ACCEPT
	iptables -A OUTPUT -p tcp -d 8.8.8.8 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT  -p tcp -s 8.8.8.8 --sport 53 -m state --state ESTABLISHED     -j ACCEPT

	#Alle anderen ankommenden Pakete werden verworfen
	echo "Alle anderen ankommenden Pakete werden verworfen"
	iptables -P INPUT   DROP
	iptables -P FORWARD DROP
	iptables -P OUTPUT  DROP

echo "Anschließend wird das Betriebssystem neu gestartet"
wait_for_key

#Restart OS
reboot
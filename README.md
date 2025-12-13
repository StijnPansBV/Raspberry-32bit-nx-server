Automatische Installatie & Watchdog Setup
Dit project bevat een Bash-installatiescript dat een Linux-systeem configureert voor:

Basisinstallatie van nuttige pakketten
Installatie van Nx Witness Server
Configuratie van een welkomstbanner
Automatische disk-mounting met UUID + LABEL
Watchdog-services voor schijven en Nx Witness
Systemd-timers voor periodieke controles


Inhoud

Benodigdheden
Installatie
Functionaliteiten
Watchdog-scripts
Systemd-services
Troubleshooting Tips
Credits


Benodigdheden

Linux distributie met apt (bijv. Ubuntu/Debian)
Internetverbinding
Rootrechten (sudo)

Installatie
Voer het script uit:

chmod +x install.sh
./install.sh

Het script doet het volgende:

Update en upgrade van het systeem
Installeert pakketten: openssh-server, cockpit, bpytop, unattended-upgrades, neofetch, figlet, wget, curl, parted, e2fsprogs
Configureert unattended-upgrades
Download en installeert Nx Witness Server (vaste versie)
Stelt een welkomstbanner in met systeeminfo
Voegt neofetch toe aan .bashrc

Functionaliteiten


Disk Watchdog:

Detecteert extra schijven (excl. OS-schijf)
Maakt partities en labels aan indien nodig
Mount schijven automatisch via UUID
Herstart systeem als geen enkele schijf gemount is (max 1x per uur)



NX Watchdog:

Controleert of Nx Witness draait
Herstart service indien nodig




Watchdog Scripts

/usr/local/bin/disk-watchdog.sh
/usr/local/bin/nx-watchdog.sh

Beide scripts loggen naar /var/log/.

Systemd Services


Disk Watchdog:

Service: /etc/systemd/system/disk-watchdog.service
Timer: /etc/systemd/system/disk-watchdog.timer (elke 30 sec)



NX Watchdog:

Service: /etc/systemd/system/nx-watchdog.service
Timer: /etc/systemd/system/nx-watchdog.timer (elke 30 sec)



Timers worden automatisch geactiveerd.

Troubleshooting Tips
1. fstab fouten of schijven niet gemount

Controleer /var/log/disk-watchdog.log voor details.
Voer handmatig uit:
sudo mount -a

sudo systemctl restart disk-watchdog.timer

systemctl status networkoptix-mediaserver.service

sudo systemctl restart networkoptix-mediaserver.service

tail -f /var/log/nx-watchdog.log

systemctl list-timers


sudo apt install -f -y

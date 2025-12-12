
Raspberry Pi 32-bit Nx Witness Server (Bookworm)
Dit project bevat een volledig automatisch installatie- en update-script voor het opzetten van een Nx Witness mediaserver op een Raspberry Pi 4 met Raspberry Pi OS (Bookworm).
✅ Functies

Automatische installatie van:

Nx Witness server
Nuttige tools (SSH, Cockpit, bpytop, unattended-upgrades, neofetch, figlet, enz.)


Tijdzone instellen op Europe/Brussels
Disk Watchdog:

Automatisch mounten van extra schijven met UUID + LABEL
Reboot als geen enkele schijf gemount is (max 1x per uur)


NX Watchdog:

Controleert of Nx Witness draait en herstart indien nodig


Systemd timers voor beide watchdogs (elke 30 seconden)
Auto-update mechanisme via GitHub:

Controleert elke 15 minuten op nieuwe versie
Voert update uit indien nodig


Volledig non-interactief:

Geen manuele input nodig
Script verwijdert zichzelf na installatie
Automatische reboot na installatie




📂 Bestanden

setup.sh
Het hoofdscript voor installatie en configuratie.
update.sh
Wordt automatisch aangemaakt door setup.sh en zorgt voor periodieke updates.


🔧 Installatie-instructies

Download en voer het script uit:
Shellgit clone https://github.com/StijnPansBV/Raspberry-32bit-nx-server-bookworm.gitcd Raspberry-32bit-nx-server-bookwormchmod +x setup.shsudo ./setup.shMeer regels weergeven

Het script:

Installeert alle vereisten
Configureert Nx Witness
Zet watchdogs en timers op
Maakt auto-update service en timer
Verwijdert zichzelf
Herstart het systeem




🔄 Automatische updates

update.sh wordt aangemaakt in /opt/update.sh.
Systemd timer (github-update.timer) draait elke 15 minuten:

Controleert GitHub repo op nieuwe commits
Voert setup.sh opnieuw uit bij verschil


Logbestand: /var/log/update.log


🛠 Handige commando’s

Update-log bekijken:
Shellcat /var/log/update.logMeer regels weergeven

Timerstatus controleren:
Shellsystemctl status github-update.timerMeer regels weergeven

Watchdog timers controleren:
Shellsystemctl status disk-watchdog.timersystemctl status nx-watchdog.timerMeer regels weergeven



✅ Versiebeheer

Het script gebruikt een versievariabele:
ShellVERSION="x.x.x"Meer regels weergeven

Bij elke update wordt deze vergeleken met /var/log/install-version.
Nieuwe versie → volledige herinstallatie.


⚠️ Belangrijk

Zorg dat Raspberry Pi OS (Bookworm) geïnstalleerd is.
Script is getest op Raspberry Pi 4.
Nx Witness versie: 6.0.6.41837 (ARM32).


Wil je dat ik ook een sectie toevoeg over hoe je de interval (15 minuten) kunt aanpassen naar een andere tijd in de README?
Of een extra sectie over hoe je handmatig een update kunt forceren?
Geef uw feedback over BizChat

Dit toestel en software wordt beheerd door de firma Stijn Pans BV.
Voor ondersteuning kan je ons bereiken via:
• 	📧 support@stijn-pans.be
• 	☎️ 016 77 08 0

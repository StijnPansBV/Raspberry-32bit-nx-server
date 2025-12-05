#!/bin/bash
set -e  # stop bij fouten

############################################################
# 0. BASISINSTALLATIE VAN HET SYSTEEM
############################################################

echo "Update en upgrade..."
sudo apt update && sudo apt upgrade -y

echo "Installeer SSH..."
sudo apt install openssh-server -y

echo "Installeer Cockpit..."
sudo apt install cockpit -y

echo "Installeer bpytop..."
sudo apt install bpytop -y

echo "Installeer unattended-upgrades..."
sudo apt install unattended-upgrades -y

echo "Configureer unattended-upgrades..."
sudo dpkg-reconfigure unattended-upgrades

echo "Download Nx Witness server package..."
wget https://updates.networkoptix.com/default/41837/arm/nxwitness-server-6.0.6.41837-linux_arm32.deb

echo "Installeer Nx Witness server..."
sudo dpkg -i nxwitness-server-6.0.6.41837-linux_arm32.deb
sudo apt install -f -y

echo "Installeer Neofetch..."
sudo apt install neofetch -y

echo "Installeer figlet..."
sudo apt install figlet -y

echo "Stel grote welkomstbanner met systeeminfo in..."
{
  figlet "Welkom Stijn Pans BV"
  echo "OS: $(lsb_release -d | cut -f2)"
  echo "Kernel: $(uname -r)"
  echo "Host: $(hostname)"
} | sudo tee /etc/motd

echo "neofetch" >> ~/.bashrc

echo "Basisinstallatie voltooid!"
sleep 2


############################################################
# 1. NX HULPTOOLS (STABIELE DETECTIE)
############################################################

mkdir -p /usr/local/bin
mkdir -p /var/log
mkdir -p /mnt/media

# nx-detect-disks.sh
cat << 'EOF' > /usr/local/bin/nx-detect-disks.sh
#!/bin/bash

# Dynamisch OS-device bepalen (disk waar / op staat)
OS_PART=$(df / | tail -1 | awk '{print $1}')
OS_DISK="/dev/$(lsblk -no PKNAME $OS_PART)"

# Alle fysieke disks ophalen
ALL_DISKS=($(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}'))

# OS-disk eruit filteren
for D in "${ALL_DISKS[@]}"; do
    if [ "$D" != "$OS_DISK" ]; then
        echo "$D"
    fi
done
EOF

# nx-format-disk.sh
cat << 'EOF' > /usr/local/bin/nx-format-disk.sh
#!/bin/bash

DISK="$1"
PART="${DISK}1"

parted "$DISK" --script mklabel gpt
parted "$DISK" --script mkpart primary 0% 100%
sleep 2
mkfs.ext4 -F "$PART"
EOF

# nx-mount-disk.sh
cat << 'EOF' > /usr/local/bin/nx-mount-disk.sh
#!/bin/bash

PART="$1"
INDEX="$2"
MOUNTPOINT="/mnt/media/disk${INDEX}"

mkdir -p "$MOUNTPOINT"

if ! grep -q "^$PART " /etc/fstab; then
    echo "$PART  $MOUNTPOINT  ext4  defaults,nofail  0  0" >> /etc/fstab
fi

mount "$MOUNTPOINT"
EOF

# nx-sync-storage.sh
cat << 'EOF' > /usr/local/bin/nx-sync-storage.sh
#!/bin/bash

INDEX=1
for PART in /dev/sd?1; do
    MOUNTPOINT="/mnt/media/disk${INDEX}"
    mkdir -p "$MOUNTPOINT"
    mount "$MOUNTPOINT" 2>/dev/null
    INDEX=$((INDEX+1))
done
EOF

# nx-verify-storage.sh
cat << 'EOF' > /usr/local/bin/nx-verify-storage.sh
#!/bin/bash

INDEX=1
for PART in /dev/sd?1; do
    MOUNTPOINT="/mnt/media/disk${INDEX}"
    if mountpoint -q "$MOUNTPOINT"; then
        echo "$PART → $MOUNTPOINT OK"
    else
        echo "$PART → $MOUNTPOINT NIET GEMOUNT"
    fi
    INDEX=$((INDEX+1))
done
EOF


############################################################
# 2. DYNAMISCHE DISK WATCHDOG (STABIELE DETECTIE)
############################################################

cat << 'EOF' > /usr/local/bin/disk-watchdog.sh
#!/bin/bash

LOGFILE="/var/log/disk-watchdog.log"
RECORD_BASE="/mnt/media"

echo "$(date): Dynamische watchdog gestart" >> "$LOGFILE"

# ✅ Dynamisch OS-disk bepalen
OS_PART=$(df / | tail -1 | awk '{print $1}')
OS_DISK="/dev/$(lsblk -no PKNAME $OS_PART)"

# ✅ Alle fysieke disks ophalen
ALL_DISKS=($(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}'))

# ✅ OS-disk eruit filteren
DISKS=()
for D in "${ALL_DISKS[@]}"; do
    if [ "$D" != "$OS_DISK" ]; then
        DISKS+=("$D")
    fi
done

# ✅ Sorteer disks voor voorspelbare volgorde
IFS=$'\n' DISKS=($(sort <<<"${DISKS[*]}"))
unset IFS

# ✅ Oude fstab-regels verwijderen
sed -i '/\/mnt\/media\/disk/d' /etc/fstab

INDEX=1
for DISK in "${DISKS[@]}"; do
    PART="${DISK}1"
    MOUNTPOINT="$RECORD_BASE/disk${INDEX}"

    # Partitie aanmaken indien nodig
    if [ ! -e "$PART" ]; then
        echo "$(date): $DISK geen partitie → aanmaken" >> "$LOGFILE"
        parted "$DISK" --script mklabel gpt
        parted "$DISK" --script mkpart primary 0% 100%
        sleep 3
        mkfs.ext4 -F "$PART"
        sleep 2
    fi

    mkdir -p "$MOUNTPOINT"

    # fstab-regel toevoegen
    echo "$PART  $MOUNTPOINT  ext4  defaults,nofail  0  0" >> /etc/fstab
    echo "$(date): fstab toegevoegd: $PART → $MOUNTPOINT" >> "$LOGFILE"

    # ✅ Mounten
    if ! mountpoint -q "$MOUNTPOINT"; then
        echo "$(date): mount $PART → $MOUNTPOINT" >> "$LOGFILE"
        mount "$MOUNTPOINT" || echo "$(date): MOUNT FAALDE" >> "$LOGFILE"
    fi

    INDEX=$((INDEX+1))
done
EOF


############################################################
# 3. NX WATCHDOG
############################################################

cat << 'EOF' > /usr/local/bin/nx-watchdog.sh
#!/bin/bash

LOGFILE="/var/log/nx-watchdog.log"

echo "$(date): NX Watchdog gestart" >> "$LOGFILE"

if ! pgrep -f "nxserver" >/dev/null; then
    echo "$(date): Nx Server draait niet → herstarten" >> "$LOGFILE"
    systemctl restart networkoptix-mediaserver.service
else
    echo "$(date): Nx Server OK" >> "$LOGFILE"
fi
EOF


############################################################
# 4. SYSTEMD SERVICES + TIMERS
############################################################

# Disk watchdog
cat << 'EOF' > /etc/systemd/system/disk-watchdog.service
[Unit]
Description=Multi-Disk Watchdog Service

[Service]
ExecStart=/usr/local/bin/disk-watchdog.sh
Type=oneshot
EOF

cat << 'EOF' > /etc/systemd/system/disk-watchdog.timer
[Unit]
Description=Run Disk Watchdog every 10 seconds

[Timer]
OnBootSec=10
OnUnitActiveSec=10

[Install]
WantedBy=timers.target
EOF

# NX watchdog
cat << 'EOF' > /etc/systemd/system/nx-watchdog.service
[Unit]
Description=NX Server Watchdog

[Service]
ExecStart=/usr/local/bin/nx-watchdog.sh
Type=oneshot
EOF

cat << 'EOF' > /etc/systemd/system/nx-watchdog.timer
[Unit]
Description=Run NX Watchdog every 30 seconds

[Timer]
OnBootSec=20
OnUnitActiveSec=30

[Install]
WantedBy=timers.target
EOF


############################################################
# 5. RECHTEN + ACTIVATIE
############################################################

chmod +x /usr/local/bin/*.sh

systemctl daemon-reload
systemctl enable --now disk-watchdog.timer
systemctl enable --now nx-watchdog.timer

echo "=== Installatie voltooid ==="
echo "Dynamische disk-mapping actief."
echo "Schijven worden altijd correct herkend en gemount."

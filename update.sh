#!/usr/bin/env bash
set -euo pipefail

# ===========================
# NX Server Update Script
# ===========================
REPO_URL="https://github.com/StijnPansBV/Raspberry-32bit-nx-server-bookworm.git"
LOCAL_SCRIPT="/usr/local/bin/setup.sh"
LOCAL_DIR="/opt/Raspberry-32bit-nx-server-bookworm"
SELF_URL="https://raw.githubusercontent.com/StijnPansBV/Raspberry-32bit-nx-server-bookworm/main/setup.sh"
LOGFILE="/var/log/nx-update.log"

# Zorg dat logbestand bestaat
touch "$LOGFILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Controleer op updates..." >> "$LOGFILE"

# Haal remote en lokale versie op
REMOTE_VERSION=$(curl -s "$SELF_URL" | grep 'SCRIPT_VERSION=' | cut -d'"' -f2 || echo "unknown")
LOCAL_VERSION=$(grep 'SCRIPT_VERSION=' "$LOCAL_SCRIPT" | cut -d'"' -f2 || echo "unknown")

echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Lokale versie: $LOCAL_VERSION | Remote versie: $REMOTE_VERSION" >> "$LOGFILE"

if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Nieuwe versie gevonden ($REMOTE_VERSION). Download en voer uit..." >> "$LOGFILE"

    # Download nieuwste setup.sh
    curl -s -o "$LOCAL_SCRIPT" "$SELF_URL"
    chmod +x "$LOCAL_SCRIPT"

    # Map verwijderen en opnieuw klonen
    if [ -d "$LOCAL_DIR" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Verwijder bestaande map: $LOCAL_DIR" >> "$LOGFILE"
        rm -rf "$LOCAL_DIR"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Kloon nieuwe versie van GitHub..." >> "$LOGFILE"
    git clone "$REPO_URL" "$LOCAL_DIR" >> "$LOGFILE" 2>&1

    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Update voltooid. Start installatie..." >> "$LOGFILE"
    exec "$LOCAL_SCRIPT" --updated
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Geen update beschikbaar." >> "$LOGFILE"
fi

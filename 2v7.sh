#!/bin/bash

set -e

# Zabbix Agent2 Upgrade Script:  2v7 by bmn-b  

echo "🔧 Starte Upgrade von Zabbix Agent 2 auf v7..."

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)

if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
    echo "❌ Diese Ubuntu-Version ($UBUNTU_VERSION) wird nicht unterstützt."
    exit 1
fi

# Backup existing Zabbix config
BACKUP_DIR="/var/backups/zabbix_agent2_$(date +%Y%m%d_%H%M%S)"
echo "🗂️ Erstelle Backup von /etc/zabbix nach $BACKUP_DIR ..."
sudo mkdir -p "$BACKUP_DIR"
sudo cp -a /etc/zabbix/* "$BACKUP_DIR" || echo "⚠️ Warnung: /etc/zabbix ist leer oder nicht vorhanden."

# Remove existing Zabbix repo
echo "🔍 Entferne alte Zabbix-Repository-Dateien (falls vorhanden)..."
sudo rm -f /etc/apt/sources.list.d/zabbix.*

# Add Zabbix 7.0 repo
echo "📦 Füge Zabbix 7.0 Repository hinzu..."

wget -qO- https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu${UBUNTU_VERSION}_all.deb -O /tmp/zabbix-release.deb

sudo dpkg --force-confnew -i /tmp/zabbix-release.deb 
sudo apt update

# Upgrade Zabbix agent2
echo "⬆️ Aktualisiere Zabbix Agent 2 auf Version 7 ..."

sudo DEBIAN_FRONTEND=noninteractive apt install --only-upgrade zabbix-agent2 zabbix-agent2-plugin-* -y -o Dpkg::Options::="--force-confold"

# Restart agent
echo "🔁 Starte Zabbix Agent 2 neu..."
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2

# Verify installation
echo "🔍 Überprüfe, ob Zabbix Agent 2 Version 7 installiert ist..."
INSTALLED_VERSION=$(zabbix_agent2 --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+')

if [[ "$INSTALLED_VERSION" =~ ^7\. ]]; then
    echo "✅ Zabbix Agent 2 Version $INSTALLED_VERSION erfolgreich installiert."
else
    echo "❌ Falsche Version installiert: $INSTALLED_VERSION"
    echo "🚨 Erwartet wurde Version 7.x – bitte prüfen Sie das Repository oder manuell nachinstallieren."
    exit 1
fi
echo "🔍 Überprüfe, ob der Zabbix Agent 2 Dienst läuft..."

if systemctl is-active --quiet zabbix-agent2; then
    echo "✅ Der Dienst 'zabbix-agent2' läuft."
else
    echo "❌ Der Dienst 'zabbix-agent2' läuft NICHT!"
    echo "📄 Ausgabe von 'systemctl status zabbix-agent2':"
    systemctl status zabbix-agent2 --no-pager
    exit 1
fi


echo "📦 Backup gespeichert unter: $BACKUP_DIR"
echo "🎉 Zabbix Agent 2 wurde erfolgreich auf Version 7 aktualisiert."
echo "OK"

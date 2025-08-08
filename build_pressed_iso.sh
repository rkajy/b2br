#!/bin/bash

set -e

# ==================== CONFIG ====================
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso"
ISO_NAME="debian.iso"
OUTPUT_ISO="debian-preseeded.iso"
WORKDIR="$(pwd)"
EXTRACTED_ISO_DIR="$WORKDIR/extracted_iso"
MOUNT_DIR="$WORKDIR/mount_iso"
PRESEED_PATH="$WORKDIR/preseed.cfg"
POST_INSTALL_PATH="$WORKDIR/post_install.sh"
MONITORING_SCRIPT_PATH="$WORKDIR/monitoring.sh"
CONFIG_DIR="$WORKDIR/config_file"
# ================================================

# Supprimer l'ancien dossier et reconstruire
rm -rf "$EXTRACTED_ISO_DIR"

echo "==> [1/8] Installation des outils requis..."
sudo apt update && sudo apt install -y wget genisoimage isolinux

if [ ! -f "$ISO_NAME" ]; then
  echo "==> [2/8] Téléchargement de l’ISO officielle Debian..."
  wget -O "$ISO_NAME" "$ISO_URL"
fi

echo "==> [3/8] Préparation des dossiers de travail..."
mkdir -p "$EXTRACTED_ISO_DIR" "$MOUNT_DIR"

# Vérification et démontage si besoin du point de montage
if mount | grep -q "$ISO_NAME"; then
  sudo umount "$MOUNT_DIR" 2>/dev/null || true
  mount | grep "$ISO_NAME" | awk '{print $3}' | xargs -r -n1 sudo umount || true
fi

echo "==> [4/8] Montage de l’ISO..."
sudo mount -o loop "$ISO_NAME" "$MOUNT_DIR"

echo "==> [5/8] Copie du contenu de l’ISO dans le répertoire de travail..."
cp -rT "$MOUNT_DIR" "$EXTRACTED_ISO_DIR"
sudo umount "$MOUNT_DIR"
sudo rm -rf "$MOUNT_DIR"

echo "==> [6/8] Ajout de preseed.cfg, post_install.sh, monitoring.sh et fichiers config dans l’ISO..."

sudo cp "$PRESEED_PATH" "$EXTRACTED_ISO_DIR/"
sudo cp "$POST_INSTALL_PATH" "$EXTRACTED_ISO_DIR/"
sudo cp "$MONITORING_SCRIPT_PATH" "$EXTRACTED_ISO_DIR/"

sudo mkdir -p "$EXTRACTED_ISO_DIR/custom_config"

shopt -s nullglob
files=("$CONFIG_DIR"/*)
if [ ${#files[@]} -gt 0 ]; then
  sudo cp "${files[@]}" "$EXTRACTED_ISO_DIR/custom_config/"
else
  echo "⚠️ Aucun fichier dans $CONFIG_DIR à copier."
fi

echo "==> [7/8] Modification de isolinux/txt.cfg pour démarrer automatiquement avec preseed..."
sudo sed -i '/label install/,/append/ s@append.*@append auto=true priority=critical preseed/file=/cdrom/preseed.cfg vga=788 initrd=/install.amd/initrd.gz langage=en country=DE locale=en_US.UTF-8 --- quiet@' "$EXTRACTED_ISO_DIR/isolinux/txt.cfg"

echo "==> [8/8] Génération de l’ISO personnalisée..."
sudo genisoimage -o "$OUTPUT_ISO" \
  -r -J -no-emul-boot -boot-load-size 4 -boot-info-table \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -V "Debian Custom ISO" \
  -input-charset utf-8 \
  "$EXTRACTED_ISO_DIR"

if [ $? -eq 0 ]; then
    echo "✅ ISO générée avec succès : $WORKDIR/$OUTPUT_ISO"
else
    echo "❌ Échec lors de la génération de l’ISO."
    exit 1
fi

echo "Commande pour récupérer la nouvelle ISO personnalisée :"
echo "scp -P 4242 radandri@127.0.0.1:/home/radandri/b2br/$OUTPUT_ISO ."
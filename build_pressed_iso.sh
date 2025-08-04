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
# ================================================

echo "==> [1/8] Installation des outils requis..."
sudo apt update && sudo apt install -y wget genisoimage isolinux

echo "==> [2/8] Téléchargement de l’ISO officielle Debian..."
wget -O "$ISO_NAME" "$ISO_URL"

echo "==> [3/8] Préparation des dossiers de travail..."
mkdir -p "$EXTRACTED_ISO_DIR" "$MOUNT_DIR"

echo "==> [4/8] Montage de l’ISO..."
sudo mount -o loop "$ISO_NAME" "$MOUNT_DIR"

echo "==> [5/8] Copie du contenu de l’ISO dans le répertoire de travail..."
cp -rT "$MOUNT_DIR" "$EXTRACTED_ISO_DIR"
sudo umount "$MOUNT_DIR"
rm -rf "$MOUNT_DIR"

echo "==> [6/8] Ajout de preseed.cfg dans l’ISO..."
cp "$PRESEED_PATH" "$EXTRACTED_ISO_DIR/"

echo "==> [7/8] Modification de isolinux/txt.cfg pour démarrer automatiquement avec preseed..."
sed -i '/label install/,/append/ s@append.*@append auto=true priority=critical preseed/file=/cdrom/preseed.cfg vga=788 initrd=/install.amd/initrd.gz --- quiet@' "$EXTRACTED_ISO_DIR/isolinux/txt.cfg"

echo "==> [8/8] Génération de l’ISO personnalisée..."
genisoimage -o "$OUTPUT_ISO" \
  -r -J -no-emul-boot -boot-load-size 4 -boot-info-table \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -V "Debian Custom ISO" \
  -input-charset utf-8 \
  "$EXTRACTED_ISO_DIR"

# ✅ Vérification de la commande précédente
if [ $? -eq 0 ]; then
    echo "✅ ISO générée avec succès : $WORKDIR/$OUTPUT_ISO"
else
    echo "❌ Échec lors de la génération de l’ISO."
    exit 1
fi
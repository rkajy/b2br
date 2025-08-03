#!/bin/bash

sudo apt update
sudo apt install wget genisoimage isolinux -y

# Variables
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
ISO_NAME="debian.iso"
ISO_DIR="$HOME/iso_build"
EXTRACTED_DIR="$ISO_DIR/iso"
PRESEED_FILE="$HOME/preseed.cfg"
OUTPUT_ISO="debian-preseeded.iso"

# 1. Préparation
mkdir -p "$EXTRACTED_DIR"
cd "$ISO_DIR" || exit

# 2. Télécharger l'ISO officielle
echo "==> Téléchargement de l’ISO officielle Debian..."
wget -O "$ISO_NAME" "$ISO_URL"

# 3. Monter l'ISO
echo "==> Montage de l’ISO..."
sudo mount -o loop "$ISO_NAME" /mnt

# 4. Copier le contenu de l’ISO
echo "==> Copie du contenu ISO vers $EXTRACTED_DIR..."
cp -rT /mnt "$EXTRACTED_DIR"
sudo umount /mnt

# 5. Ajouter le fichier preseed.cfg
echo "==> Ajout du fichier preseed.cfg..."
cp "$PRESEED_FILE" "$EXTRACTED_DIR"

# 6. Modifier isolinux
echo "==> Modification du fichier isolinux/txt.cfg..."
sed -i '/label install/,/append/ s@append.*@append auto=true priority=critical preseed/file=/cdrom/preseed.cfg vga=788 initrd=/install.amd/initrd.gz --- quiet@' "$EXTRACTED_DIR/isolinux/txt.cfg"

# 7. Générer la nouvelle ISO
echo "==> Génération de la nouvelle ISO : $OUTPUT_ISO"
genisoimage -o "$OUTPUT_ISO" \
  -r -J -no-emul-boot -boot-load-size 4 -boot-info-table \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -V "Debian Custom ISO" \
  -input-charset utf-8 \
  "$EXTRACTED_DIR"

echo "✅ ISO générée avec succès : $ISO_DIR/$OUTPUT_ISO"
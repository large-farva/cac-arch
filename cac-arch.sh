#!/bin/bash

# CAC/PIV Setup Script for Arch Linux
# This script automates the setup of a CAC/PIV (Common Access Card / Personal Identity Verification) card on Arch Linux.

# Step 1: Update System
echo "Step 1: Updating system..."
sudo pacman -Syu --noconfirm

# Step 2: Install Dependencies
echo "Step 2: Installing dependencies..."
sudo pacman -S pcsc-tools ccid pcsclite opensc nss --noconfirm

# Step 3: Enable and Start the pcscd Daemon
echo "Step 3: Enabling and starting the pcscd daemon..."
sudo systemctl enable pcscd.service
sudo systemctl start pcscd.service

# Step 4: Check if pcscd is Running Properly
echo "Step 4: Checking pcscd daemon status..."
sudo systemctl status pcscd.service

# Step 5: Configure OpenSC
echo "Step 5: Configuring OpenSC..."
if ! grep -q 'force_card_driver' /etc/opensc/opensc.conf; then
    echo -e '\n# Adding CAC card drivers to OpenSC configuration\ncard_drivers = cac\nforce_card_driver = cac' | sudo tee -a /etc/opensc/opensc.conf
fi

# Step 6: Download DoD Certificates
echo "Step 6: Downloading DoD certificates..."
wget https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/certificates_pkcs7_DoD.zip && unzip certificates_pkcs7_DoD.zip

# Step 7: Import DoD Certificates to Firefox
echo "Step 7: Importing DoD certificates to Firefox..."
for cert_file in Certificates_PKCS7_v5.7_DoD*.p7b; do
    echo "Importing $cert_file to Firefox..."
    certutil -d sql:$HOME/.mozilla/firefox/*.default-release -A -t "C," -n "$cert_file" -i "$cert_file"
done

# Step 8: Add CAC Module to NSS DB for Chromium-Based Browsers
echo "Step 8: Adding CAC module to NSS DB for Chromium-based browsers..."
modutil -dbdir sql:$HOME/.pki/nssdb/ -add "OpenSC smartcard framework" -libfile /usr/lib/opensc-pkcs11.so

# Step 9: Import DoD Certificates to Chromium-Based Browsers
echo "Step 9: Importing DoD certificates to NSS DB for Chromium-based browsers..."
for n in *.p7b; do
    echo "Importing $n to NSS DB..."
    certutil -d sql:$HOME/.pki/nssdb -A -t TC -n $n -i $n
done

# Step 10: Import DoD Certificates to System Certificate Store
echo "Step 10: Importing DoD certificates to system certificate store..."
openssl pkcs7 -print_certs -in Certificates_PKCS7_v5.7_DoD.pem.p7b -out dod_bundle.pem

awk 'split_after == 1 {n++; split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "cert" n ".crt"}' < dod_bundle.pem

echo "Creating directory for DoD certificates and copying CRT files..."
sudo mkdir -p /etc/ca-certificates/trust-source/dod/
sudo cp *.crt /etc/ca-certificates/trust-source/dod/

# Step 11: Update Certificate Store
echo "Updating certificate store..."
sudo update-ca-trust

echo "Setup Complete! You are now fully CAC enabled on your Arch Linux system."

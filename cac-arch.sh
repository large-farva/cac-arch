#!/bin/bash

# Script to set up DoD CAC on Arch Linux for Firefox and Chromium

set -e

# Install necessary packages
echo "Installing required packages..."
sudo pacman -Syu --noconfirm ccid opensc pcsc-tools

read -p "Do you want to install Chromium? (Recommended) (y/n): " install_chromium
if [[ "$install_chromium" == "y" ]]; then
    echo "Installing Chromium..."
    sudo pacman -S --noconfirm chromium
fi

read -p "Do you want to install Firefox? (y/n): " install_firefox
if [[ "$install_firefox" == "y" ]]; then
    echo "Installing Firefox..."
    sudo pacman -S --noconfirm firefox
fi
echo "------------------------------"


# Configure OpenSC
echo "Configuring OpenSC..."
if grep -q "enable_pinpad=false" /etc/opensc.conf; then
    echo "OpenSC already configured."
else
    echo "enable_pinpad=false" | sudo tee -a /etc/opensc.conf
fi
echo "------------------------------"

# Enable and restart pcscd service
echo "Enabling and restarting pcscd service..."
sudo systemctl enable pcscd.service
sudo systemctl restart pcscd.socket
echo "------------------------------"

# Test the smart card reader
read -p "Do you want to test your smart card reader now? (y/n): " test_reader
if [[ "$test_reader" == "y" ]]; then
    echo "Testing smart card reader for 10 seconds..."
    timeout 10 pcsc_scan
else
    echo "Skipping smart card reader test."
fi
echo "------------------------------"

# Cleanup function
cleanup() {
    echo "Cleaning up old certificate archives..."
    if [[ -d "$CERTS_DIR" ]]; then
        rm -rf "$CERTS_DIR/$CERTS_ZIP"
    fi
    echo "Cleanup completed."
}
echo "------------------------------"

# Download DoD CAC certificates with retry logic
CERTS_URL="https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_v5-6_dod.zip"
CERTS_ZIP="unclass-certificates_pkcs7_v5-6_dod.zip"
CERTS_DIR="$HOME/.certs"

mkdir -p "$CERTS_DIR"

download_certificates() {
    local retries=3
    local success=0
    for ((i=1; i<=retries; i++)); do
        echo "Downloading DoD CAC certificates (attempt $i of $retries)..."
        wget -O "$CERTS_DIR/$CERTS_ZIP" "$CERTS_URL" && success=1 && break
        echo "Download failed. Retrying..."
        sleep 5
    done

    if [[ $success -eq 0 ]]; then
        echo "Failed to download certificates after $retries attempts. Exiting."
        exit 1
    fi
}

download_certificates

unzip -o "$CERTS_DIR/$CERTS_ZIP" -d "$CERTS_DIR"
echo "------------------------------"

# Save Firefox instructions
FIREFOX_INSTRUCTIONS="$HOME/Downloads/firefox-instructions.txt"
cat <<EOF > "$FIREFOX_INSTRUCTIONS"
Firefox Setup Instructions:

1. Open Firefox and go to the 'Privacy & Security' tab in Settings.
2. Scroll to the Certificates section and click 'View Certificates'.
3. Under Authorities, click 'Import', navigate to the DoD certificates directory at "$CERTS_DIR".
4. Select 'Certificates_PKCS7_v5.6_DoD.der.p7b'.
5. Check all trust boxes and click OK.
6. In the same Privacy & Security tab, click 'Security Devices'.
7. Click 'Load', enter 'CAC Module' for Module Name.
8. Browse to "/usr/lib64/",click on "opensc-pkcs11.so", and click OK.
9. Close/Reopen Firefox and go to a DoD CAC-enabled website.

Note: You may need to reboot your computer. Also, if Firefox fails to read your certificate run this 
EOF

echo "Firefox setup instructions saved to $FIREFOX_INSTRUCTIONS."

# Save Chromium instructions
CHROMIUM_INSTRUCTIONS="$HOME/Downloads/chromium-instructions.txt"
cat <<EOF > "$CHROMIUM_INSTRUCTIONS"
Chromium Setup Instructions:

1. Open Chromium and go to the 'Privacy and Security' tab in Settings.
2. Then click 'Manage certificates'.
3. Under 'Authorities', click 'Import'.
4. Navigate to the DoD certificates directory at "$CERTS_DIR".
5. Select 'Certificates_PKCS7_v5-6_DoD.der.p7b'.
6. Check all trust boxes and click OK.
7. Open a terminal and execute this 'modutil -dbdir sql:.pki/nssdb/ -add "CAC Module" -libfile /usr/lib64/opensc-pkcs11.so'. This loads your Security Device Module 
8. Execute 'modutil -dbdir sql:.pki/nssdb/ -list' and make sure 'CAC Module' is visible.
9. Close/Reopen Chromium and go to a DoD CAC-enabled website.

b. Note: You may need to reboot your computer.
EOF

echo "Chromium setup instructions saved to $CHROMIUM_INSTRUCTIONS."

# Call cleanup
cleanup

echo "DoD CAC setup script completed. Please proceed with the browser setup."

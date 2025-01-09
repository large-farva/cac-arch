#!/bin/bash

set -e
LOGFILE="cac_setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Paths and URLs
CERTS_URL="https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_v5-6_dod.zip"
CERTS_DIR="$HOME/.certs"
CHROMIUM_INSTRUCTIONS="$HOME/Downloads/chromium-instructions.txt"
FIREFOX_INSTRUCTIONS="$HOME/Downloads/firefox-instructions.txt"

# Colors for output
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

# Script version
SCRIPT_VERSION="1.0.0"

# Functions
log() {
    local level="$1"
    shift
    printf "[%s] %s\n" "$level" "$*" | tee -a "$LOGFILE"
}

colored_message() {
    local color="$1"
    local message="$2"
    printf "%b%s%b\n" "$color" "$message" "$RESET"
}

prompt_user() {
    local prompt_msg="$1"
    local valid_input="n"
    while true; do
        read -p "$prompt_msg (y/n): " valid_input
        case "$valid_input" in
            y|n) break ;;
            *) printf "Invalid input. Please enter 'y' or 'n'.\n" ;;
        esac
    done
    echo "$valid_input"
}

retry_command() {
    local retries="$1"
    shift
    local cmd="$*"
    local count=0

    until $cmd; do
        count=$((count + 1))
        if (( count >= retries )); then
            log "ERROR" "Command '$cmd' failed after $retries attempts."
            return 1
        fi
        sleep 2
        log "WARN" "Retrying command '$cmd'... Attempt $count."
    done
    return 0
}

trap_cleanup() {
    log "INFO" "Cleaning up temporary files..."
    rm -f "$CERTS_DIR"/*.zip
    log "INFO" "Cleanup completed."
}
trap trap_cleanup EXIT

main() {
    colored_message "$GREEN" "Running DoD CAC Setup Script - Version $SCRIPT_VERSION"
    update_system
    install_packages
    remove_conflicting_packages
    browser_installation
    configure_opensc
    manage_pcscd_service
    smart_card_reader_test
    download_certificates
    save_instructions
    prompt_reboot
    log "INFO" "DoD CAC setup script completed. Please proceed with the browser setup."
}

update_system() {
    log "INFO" "Updating the system..."
    retry_command 3 sudo pacman -Syu --noconfirm
    colored_message "$GREEN" "System update completed."
}

install_packages() {
    log "INFO" "Installing required packages..."
    retry_command 3 sudo pacman -Syu --noconfirm ccid opensc pcsc-tools
    colored_message "$GREEN" "Required packages installed."
}

remove_conflicting_packages() {
    log "INFO" "Uninstalling conflicting packages..."
    sudo pacman -R --noconfirm cackey coolkey || true
    colored_message "$GREEN" "Conflicting packages removed."
}

browser_installation() {
    for browser in "Chromium" "Firefox"; do
        if [[ "$(prompt_user "Do you want to install $browser?")" == "y" ]]; then
            log "INFO" "Installing $browser..."
            retry_command 3 sudo pacman -S --noconfirm "${browser,,}"
            colored_message "$GREEN" "$browser installed."
        fi
    done
}

configure_opensc() {
    log "INFO" "Configuring OpenSC..."
    if ! grep -q "enable_pinpad=false" /etc/opensc.conf; then
        echo "enable_pinpad=false" | sudo tee -a /etc/opensc.conf > /dev/null
        colored_message "$GREEN" "OpenSC configured successfully."
    else
        log "INFO" "OpenSC already configured."
    fi
}

manage_pcscd_service() {
    log "INFO" "Enabling and restarting pcscd service..."
    sudo systemctl enable --now pcscd.socket
    colored_message "$GREEN" "pcscd service enabled and restarted."
}

smart_card_reader_test() {
    if [[ "$(prompt_user "Do you want to test your smart card reader now?")" == "y" ]]; then
        log "INFO" "Testing smart card reader for 10 seconds..."
        if ! timeout 10 pcsc_scan; then
            colored_message "$RED" "Smart card reader test failed."
        fi
    else
        log "INFO" "Skipping smart card reader test."
    fi
}

download_certificates() {
    log "INFO" "Downloading DoD CAC certificates..."
    mkdir -p "$CERTS_DIR"
    retry_command 3 wget -q -O "$CERTS_DIR/certs.zip" "$CERTS_URL"
    unzip -o "$CERTS_DIR/certs.zip" -d "$CERTS_DIR"
    colored_message "$GREEN" "Certificates downloaded and extracted."
}

save_instructions() {
    log "INFO" "Saving browser setup instructions..."
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

Note: 
You may need to reboot your computer.

If Chromium can't read your certificate, close Chromium, run 'sudo systemctl restart pcscd.socket', and then restart Chromium.
EOF

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

Note: 
You may need to reboot your computer.

If Firefox can't read your certificate, close Firefox, run 'sudo systemctl restart pcscd.socket', and then restart Firefox.
EOF

    colored_message "$GREEN" "Instructions saved to:\n- $CHROMIUM_INSTRUCTIONS\n- $FIREFOX_INSTRUCTIONS"
}

prompt_reboot() {
    if [[ "$(prompt_user "Do you want to reboot now?")" == "y" ]]; then
        log "INFO" "Rebooting the system..."
        sudo reboot
    else
        colored_message "$YELLOW" "Reboot skipped. Please remember to reboot later to complete the setup."
    fi
}

main "$@"

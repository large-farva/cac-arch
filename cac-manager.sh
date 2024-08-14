#!/bin/bash

# Nord color scheme
declare -A nord=(
    [0]="#2E3440"  # Background
    [1]="#3B4252"  # Darker Background
    [2]="#434C5E"  # Selection Background
    [3]="#4C566A"  # Comments, Invisible Characters
    [4]="#D8DEE9"  # Light Text
    [5]="#E5E9F0"  # Lighter Text
    [6]="#ECEFF4"  # Lighter Text (brightest)
    [7]="#8FBCBB"  # Aqua/Cyan
    [8]="#88C0D0"  # Light Cyan
    [9]="#81A1C1"  # Blue
    [10]="#5E81AC" # Dark Blue
    [11]="#BF616A" # Red
    [12]="#D08770" # Orange
    [13]="#EBCB8B" # Yellow
    [14]="#A3BE8C" # Green
    [15]="#B48EAD" # Purple
)

# Function to display styled messages
display_message() {
    local message_type=$1
    local message=$2
    local color=${nord[$3]}
    gum style --foreground "$color" --border normal --margin "1" --padding "1" "$message"
    [[ "$message_type" == "error" ]] && gum confirm "Press enter to return to the main menu"
}

# Function to prompt for sudo password at the start
prompt_sudo() {
    display_message info "🔒 Please enter your sudo password to proceed:" 9
    sudo -v || display_message error "❌ Failed to obtain sudo privileges." 11
}

# Unified function for package management
manage_packages() {
    local action=$1
    shift
    local packages=("$@")
    local total=${#packages[@]}
    local current=0

    for package in "${packages[@]}"; do
        current=$((current + 1))
        echo "$current/$total ${action^}ing $package..."
        if ! yay -S --noconfirm "$package"; then
            display_message error "❌ Failed to $action $package. Package not found." 11
            continue
        fi
    done

    display_message success "✅ All packages processed successfully." 14
}

# Install Packages Function
install_packages() {
    manage_packages "install" "nss" "pcsclite" "libpcsc-perl" "pcsc-tools" "ccid" "libccid" "opensc" "opensc-pkcs11"
}

# Remove Conflicting Packages Function
remove_conflicting_packages() {
    local packages=("cackey" "coolkey")
    for package in "${packages[@]}"; do
        echo "Removing $package..."
        if yay -Q "$package" &>/dev/null; then
            if ! yay -Rns --noconfirm "$package"; then
                display_message error "❌ Failed to remove $package." 11
                continue
            fi
            display_message success "✅ $package removed successfully." 14
        else
            display_message info "ℹ️ $package is not installed." 13
        fi
    done
}

# Function to start and enable a service
start_service() {
    local service=$1
    sudo systemctl start "$service" && sudo systemctl enable "$service" || display_message error "❌ Failed to start and enable $service." 11
    display_message success "✅ $service started and enabled successfully." 14
}

# Function to manage pcsc_scan process
manage_pcsc_scan() {
    gum style --foreground "${nord[7]}" "🔍 Press Enter to stop pcsc_scan and return to the menu."
    pcsc_scan &
    read -r -p ""
    pkill -f pcsc_scan
    display_message success "✅ pcsc_scan stopped. Returning to the main menu." 14
}

# Function to handle PCSC daemon errors
handle_pcsc_errors() {
    start_service "pcscd.socket"
    start_service "pcscd.service"
    gum style --foreground "${nord[12]}" "⚠️ If you're seeing 'scanning present readers waiting for the first reader...', we'll unload kernel modules."
    gum confirm "🔧 Ready to unload kernel modules?" && sudo modprobe -r pn533 nfc || display_message error "❌ Failed to unload kernel modules." 11
    display_message success "✅ Kernel modules unloaded successfully." 14
}

# Function to verify drivers
verify_drivers() {
    gum spin --spinner dot --title "🔄 Verifying drivers with opensc-tools..." --foreground "${nord[13]}" -- opensc-tool -l || display_message error "❌ Failed to verify drivers with opensc-tools." 11
    gum style --foreground "${nord[10]}" "ℹ️ If your smartcard reader is not listed, update /etc/opensc/opensc.conf."
}

# Function to update /etc/opensc/opensc.conf
update_opensc_conf() {
    display_message info "🔧 Adding necessary configurations to /etc/opensc/opensc.conf..." 9
    sudo tee /etc/opensc/opensc.conf > /dev/null <<EOL
app default {
    card_drivers = cac
    force_card_driver = cac
    framework pkcs15 {
    # use_file_caching = true;
    }
}
EOL
    [[ $? -eq 0 ]] && display_message success "✅ /etc/opensc/opensc.conf updated successfully." 14 || display_message error "❌ Failed to update /etc/opensc/opensc.conf." 11
}

# Function to download DoD Certificates
download_dod_certs() {
    gum spin --spinner dot --title "⬇️ Downloading DoD Certificates..." --foreground "${nord[7]}" -- \
        cd ~/Documents && wget https://militarycac.com/maccerts/AllCerts.zip && unzip AllCerts.zip -d dod-certs || display_message error "❌ Failed to download and unzip DoD certificates." 11
    display_message success "✅ DoD certificates downloaded successfully." 14
}

# Unified Function to Configure Browsers
configure_browser() {
    local browser=$1
    local configure_command=$2
    local cert_import_path=$3
    local cert_command=$4

    gum spin --spinner dot --title "🔄 Configuring $browser for CAC..." --foreground "${nord[8]}" -- $configure_command || display_message error "❌ Failed to configure $browser." 11
    display_message success "✅ $browser configured successfully." 14

    if [[ -n $cert_import_path && -n $cert_command ]]; then
        gum spin --spinner dot --title "🔄 Importing DoD certificates into $browser..." --foreground "${nord[9]}" -- cd "$cert_import_path" || display_message error "❌ Failed to navigate to DoD certificates directory." 11
        for cert in *.p7b *.pem; do
            $cert_command "$cert" || display_message error "❌ Failed to import DoD certificate $cert." 11
        done
        display_message success "✅ DoD certificates imported into $browser successfully." 14
    fi
}

# Specific Browser Configuration Functions
configure_firefox() {
    configure_browser "Firefox" "pkcs11-register"
}

configure_chromium() {
    configure_browser "Chrome/Chromium" "sudo modutil -dbdir sql:$HOME/.pki/nssdb/ -add 'CAC Module' -libfile /usr/lib/opensc-pkcs11.so" "~/Documents/dod-certs" "sudo certutil -d sql:$HOME/.pki/nssdb -A -t TC -n"
}

# Interactive menu with descriptions
interactive_prompt() {
    while true; do
        local options=(
            "📦 Install Packages: Install necessary packages for CAC."
            "❌ Remove Conflicting Packages: Remove cackey and coolkey to avoid conflicts."
            "🖥️ Start PCSC Daemon: Start and enable the PCSC daemon."
            "🔍 Verify CAC Reader: Run pcsc_scan to verify the CAC reader."
            "🔧 Handle PCSC Errors: Troubleshoot and fix PCSC daemon issues."
            "🔄 Verify Drivers: Verify drivers using opensc-tools."
            "🛠️ Update opensc.conf: Update the /etc/opensc/opensc.conf file."
            "⬇️ Download DoD Certificates: Download and unzip DoD certificates."
            "🌐 Configure Firefox: Configure Firefox for CAC."
            "🌐 Configure Chrome/Chromium: Configure Chrome/Chromium for CAC."
            "🚪 Quit: Exit the script."
        )

        local choice=$(printf "%s\n" "${options[@]}" | gum choose --height 15 --cursor.foreground "${nord[8]}" --item.foreground "${nord[9]}" --selected.foreground "${nord[7]}")

        case $choice in
            "📦 Install Packages: Install necessary packages for CAC.") install_packages ;;
            "❌ Remove Conflicting Packages: Remove cackey and coolkey to avoid conflicts.") remove_conflicting_packages ;;
            "🖥️ Start PCSC Daemon: Start and enable the PCSC daemon.") start_service "pcscd" ;;
            "🔍 Verify CAC Reader: Run pcsc_scan to verify the CAC reader.") manage_pcsc_scan ;;
            "🔧 Handle PCSC Errors: Troubleshoot and fix PCSC daemon issues.") handle_pcsc_errors ;;
            "🔄 Verify Drivers: Verify drivers using opensc-tools.") verify_drivers ;;
            "🛠️ Update opensc.conf: Update the /etc/opensc/opensc.conf file.") update_opensc_conf ;;
            "⬇️ Download DoD Certificates: Download and unzip DoD certificates.") download_dod_certs ;;
            "🌐 Configure Firefox: Configure Firefox for CAC.") configure_firefox ;;
            "🌐 Configure Chrome/Chromium: Configure Chrome/Chromium for CAC.") configure_chromium ;;
            "🚪 Quit: Exit the script.") echo "👋 Exiting..."; exit 0 ;;
            *) display_message error "❌ Invalid option selected." 11 ;;
        esac

        gum confirm "🔁 Press enter to return to the main menu"
    done
}

# Main script execution with enhanced styling
gum style --foreground "${nord[9]}" --border normal --margin "1" --padding "2" "✨ CAC Manager ✨"
prompt_sudo
interactive_prompt

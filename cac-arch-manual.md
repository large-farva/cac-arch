# Manual Instructions for Setting Up DoD CAC on Arch Linux

## Overview
These instructions detail the manual steps to set up a Common Access Card (CAC) on Arch Linux. This includes configuring the system, installing necessary software, and setting up CAC compatibility for Firefox and Chromium browsers.

## Step-by-Step Instructions

### 1. Update the System
Ensure your system is up-to-date with the latest packages:
```bash
sudo pacman -Syu
```

### 2. Install Required Packages
Install the necessary dependencies for CAC functionality:
```bash
sudo pacman -Syu --noconfirm ccid opensc pcsc-tools
```

### 3. Remove Conflicting Packages
Uninstall packages that may interfere with OpenSC:
```bash
sudo pacman -R --noconfirm cackey coolkey
```

### 4. Install Browsers
#### Install Chromium (Recommended):
If you prefer Chromium, install it:
```bash
sudo pacman -S --noconfirm chromium
```

#### Install Firefox:
If you prefer Firefox, install it:
```bash
sudo pacman -S --noconfirm firefox
```

### 5. Configure OpenSC
Edit the OpenSC configuration file to disable the PIN pad (if your reader does not have one):
```bash
echo "enable_pinpad=false" | sudo tee -a /etc/opensc.conf
```

### 6. Enable and Restart `pcscd` Service
Start and enable the smart card service:
```bash
sudo systemctl enable pcscd.service
sudo systemctl restart pcscd.socket
```

### 7. Test the Smart Card Reader
Test your smart card reader to ensure it is functioning:
```bash
pcsc_scan
```
To limit the test to 10 seconds, use:
```bash
timeout 10 pcsc_scan
```

### 8. Download DoD Certificates
#### Create a Directory for Certificates:
```bash
mkdir -p $HOME/.certs
```

#### Download Certificates with Retry Logic:
Use the following commands to download DoD certificates:
```bash
CERTS_URL="https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_v5-6_dod.zip"
CERTS_ZIP="$HOME/.certs/unclass-certificates_pkcs7_v5-6_dod.zip"
wget -O "$CERTS_ZIP" "$CERTS_URL"
```

#### Extract the Certificates:
```bash
unzip -o "$CERTS_ZIP" -d "$HOME/.certs"
```

### 9. Configure Chromium
#### Import DoD Certificates:
1. Open Chromium.
2. Navigate to `Privacy and Security` in Settings.
3. Click `Manage Certificates`.
4. Under `Authorities`, click `Import` and select:
   ```
   $HOME/.certs/Certificates_PKCS7_v5.6_DoD.der.p7b
   ```
5. Check all trust boxes and click OK.

#### Add the Security Module:
1. Open a terminal and execute:
   ```bash
   modutil -dbdir sql:.pki/nssdb/ -add "CAC Module" -libfile /usr/lib64/opensc-pkcs11.so
   ```
2. Verify the module was added:
   ```bash
   modutil -dbdir sql:.pki/nssdb/ -list
   ```

#### Restart Chromium and Test:
Restart Chromium and access a CAC-enabled website.

### 10. Configure Firefox
#### Import DoD Certificates:
1. Open Firefox.
2. Navigate to `Privacy & Security` in Settings.
3. Under `Certificates`, click `View Certificates`.
4. Under `Authorities`, click `Import` and select:
   ```
   $HOME/.certs/Certificates_PKCS7_v5.6_DoD.der.p7b
   ```
5. Check all trust boxes and click OK.

#### Add the Security Module:
1. Under `Security Devices`, click `Load`.
2. Enter `CAC Module` for the Module Name.
3. Browse to:
   ```
   /usr/lib64/opensc-pkcs11.so
   ```
4. Click OK.

#### Restart Firefox and Test:
Restart Firefox and access a CAC-enabled website.

### 11. Cleanup
Remove any temporary certificate archives:
```bash
rm -rf $HOME/.certs/unclass-certificates_pkcs7_v5-6_dod.zip
```

### Troubleshooting
- **`pcscd` Daemon Issues**:
  Ensure the `pcscd` service is running:
  ```bash
  sudo systemctl status pcscd.socket
  ```
  Restart the service if necessary:
  ```bash
  sudo systemctl restart pcscd.socket
  ```

- **Browser Not Recognizing CAC**:
  - Verify the security module is correctly loaded.
  - Restart the `pcscd` service and the browser:
    ```bash
    sudo systemctl restart pcscd.socket
    ```


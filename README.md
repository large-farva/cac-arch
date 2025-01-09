# CAC Setup Script for Arch Linux

## Overview

This script automates the setup of a CAC/PIV (Common Access Card / Personal Identity Verification) card on Arch Linux. It ensures that all necessary dependencies are installed, configures the environment, and sets up browser integration for CAC functionality. The script supports both Firefox and Chromium-based browsers.

## Features

- Updates the system and installs required dependencies for CAC operation.
- Installs required dependencies for CAC operation.
- Configures the `pcscd` service to interact with the smart card reader.
- Configures OpenSC for CAC compatibility.
- Downloads and installs the latest DoD certificates with retry logic for network stability.
- Guides you through setting up Firefox and Chromium for CAC functionality.

## Prerequisites

- Arch Linux distribution (e.g., Arch Linux, EndeavourOS).
- Root or sudo access for package installation and system configuration.
- A USB smart card reader.
- Stable internet connection.

## Usage

1. **Clone the Repository**
  `git clone https://github.com/large-farva/cac-arch.git
  cd cac-arch`
2. Make the Script Executable
  `chmod +x cac-arch.sh`
3. Run Script
  `sudo ./cac-arch.sh`

The script will guide you through each step, including optional installation of Chromium and Firefox, configuration of services, and downloading and importing DoD certificates.

## Script Steps

1. **Update System**: Ensures your system is updated with the latest package versions.
2. **Install Dependencies**: Installs `pcsc-tools`, `opensc`, `ccid`, and optionally Chromium and Firefox.
3. **Enable and Start `pcscd` Service**: Starts the smart card service for CAC detection.
4. **Configure OpenSC**: Updates `/etc/opensc.conf` with necessary settings for CAC cards.
5. **Test Smart Card Reader**: Optionally verifies the reader functionality with `pcsc_scan` (10-second timeout).
6. **Download DoD Certificates**: Downloads the latest certificates, with retry logic for failed downloads.
7. **Import DoD Certificates into Browsers**: Saves instructions for Firefox and Chromium in `~/Downloads` for manual setup.
8. **Cleanup**: Removes temporary certificate archives after installation.

## Troubleshooting

- **`pcscd` Daemon Issues**: If the script fails to detect the smart card reader, ensure the `pcscd`service is running:
  `sudo systemctl status pcscd.socket`
  Restart the service if necessary: (I recommend making an alias!)
  `sudo systemctl restart pcscd.socket`
  
- **Browser Setup Issues: **If Firefoc or Chromium doesn't recongnize the CAC:
  
  - Ensure the `opensc-pkcs11.so` module is correctly loaded in the browser.
    
  - Restart `pcscd` service:
    `sudo systemctl restart pcscd.socket`
    
  - Restart the browser and try again.
    

## Notes

- This script is optimized for CAC, but may work with PIV cards as well.
  
- Adjust paths for `onepin-opensc-pkcs11.so` if using dual-use CACs.
  
- Follow the browser instructionws saved in ~/Downloads adfter running the script.
  

## Disclaimer

This script is provided "as is" without any warranties. Use at your own risk. Always back up your system before making changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributions

Feel free to open issues or submit pull requests for improvements. Feedback is always welcome!

##Author

- Sebastian (Github: large-farva)

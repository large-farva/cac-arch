# CAC/PIV Setup Script for Arch Linux

## Overview

This script automates the setup of a CAC/PIV (Common Access Card / Personal Identity Verification) card on Arch Linux. It ensures that all necessary dependencies are installed, configures the environment, and sets up browser integration for CAC functionality. This script is specifically designed for users working with US government CACs, and it provides compatibility with both Firefox and Chromium-based browsers.

## Features

- Updates system and installs necessary dependencies for CAC operation.
- Configures the `pcscd` service to interact with the smart card reader.
- Configures OpenSC to handle CAC cards effectively.
- Downloads and installs the latest DoD certificates for browser integration.
- Sets up Firefox and Chromium-based browsers to use CAC certificates for secure access.

## Prerequisites

- An Arch Linux distribution (e.g., Arch Linux, EndeavourOS, Archo Linux).
- Root or sudo access to install and configure packages.
- A USB smart card reader.

## Usage

1. **Clone the Repository**
  
  ```bash
  git clone <repository_url>
  cd <repository_directory>
  ```
  
2. **Make the Script Executable**
  
  ```bash
  chmod +x cac_arch_setup.sh
  ```
  
3. **Run the Script**
  
  ```bash
  sudo ./cac_arch_setup.sh
  ```
  

The script will guide you through each step, displaying messages about what is currently being configured or installed. Please ensure that you have a stable internet connection as the script will download dependencies and certificates.

## Script Steps

1. **Update System**: Ensures your system is up to date with the latest package versions.
2. **Install Dependencies**: Installs all necessary dependencies, including `pcsc-tools`, `opensc`, and `ccid`.
3. **Enable and Start pcscd Daemon**: Enables and starts the smart card service (`pcscd`) to detect the CAC reader.
4. **Check pcscd Status**: Verifies that the `pcscd` daemon is running properly.
5. **Configure OpenSC**: Adds required configurations to `/etc/opensc/opensc.conf` to support CAC cards.
6. **Download DoD Certificates**: Downloads the latest DoD certificates required for authentication.
7. **Import DoD Certificates to Firefox**: Imports downloaded certificates to Firefox to enable secure access using CAC.
8. **Add CAC Module to NSS DB for Chromium-Based Browsers**: Configures Chromium-based browsers to use the OpenSC PKCS11 module.
9. **Import DoD Certificates to Chromium-Based Browsers**: Adds certificates to the NSS database for Chromium-based browsers.
10. **Import DoD Certificates to System Certificate Store**: Installs DoD certificates into the system-wide certificate store.
11. **Update Certificate Store**: Updates the certificate store to recognize newly imported certificates.

## Troubleshooting

- **PCSC Daemon Issues**: If the script fails to detect the card, ensure the `pcscd` service is running:
  
  ```bash
  sudo systemctl status pcscd
  ```
  
  Restart the service if necessary:
  
  ```bash
  sudo systemctl restart pcscd
  ```
  
- **Browser Not Recognizing CAC**: Verify that the security module is loaded in Firefox or Chromium, and that the DoD certificates are properly imported.

## Notes

- This script is optimized for CAC cards but may work with PIV cards as well.
- The installation path for `onepin-opensc-pkcs11.so` may vary depending on the OpenSC package version. Adjust the paths in the script if necessary.

## Disclaimer

This script is provided "as is" without warranty of any kind. Use it at your own risk. Ensure you have backups and understand the changes being made to your system before executing the script.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributions

Feel free to submit pull requests or open issues if you encounter any problems or have suggestions for improvement.

## Author

- Sebastian (GitHub: [large-farva](https://github.com/large-farva))

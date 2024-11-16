# CAC Arch

### DoD CAC Support for Arch Linux.
This script walks you through all the steps needed to get your CAC to work with Chrome and Firefox, on Arch Linux. There may be problems, so please submit an issue report explaining what problems you are experiencing. Screenshots and/or logs will be helpful.\
**Clone this repo and make cac-manager.sh executable.**
```
cd ~/Downloads
git clone https://github.com/large-farva/cac-arch.git
cd cac-arch
chmod +x cac-manager
```
\
**Launch cac-manager**
```
./cac-manager.sh
```
or
```
sudo bash cac-manager.sh
```
\
The rest is pretty self explanitory.
\
**Manual instructions are still available below.**
<br />
<br />
# How to use DoD CAC on Arch Linux
~~Automation script is in the works.~~ I made that shit.
<br />
### Update and install required packages.
```
yay -Syu
yay -S nss pcsclite libpcsc-perl pcsc-tools ccid libccid opensc opensc-pkcs11
```
<br />
Make sure cackey and coolkey are uninstalled.
```
yay -R cackey coolkey
sudo pacman -Rns
```
\
### Start and enable the PCSC daemon
```
sudo systemctl start pcscd
sudo systemctl enable pcscd
```
\
### Verify your CAC reader is working correctly and can detect your CAC.
Insert your CAC, remove it, and insert it again after running 'pcsc_scan'. You should see the pcsc daemon reading your CAC when it's inserted and removed in real-time. It will also display information about your CAC.
\
```pcsc_scan```
\
**If there are errors**
```
sudo systemctl restart pcscd.socket && sudo systemctl restart pcscd.service
```
\
If you see "scanning present readers waiting for the first reader..." running the following will unload the kernel modules and allow whatever is plugged into the USB slot.
```
modprobe -r pn533 nfc
```
\
### Verify drivers
```
opensc-tools -l
```
\
You should see this if you are using our government Dell computers with the integrated smartcard readers.
```
# Detected readers (pcsc)
Nr.  Card  Features  Name
0    Yes             Broadcom Corp 58200 [Contacted SmartCard] (0123456789ABCD) 00 00
```
\
If not, add the following lines to /etc/opensc/opensc.conf
```
card_drivers = cac
force_card_driver = cac
```
\
Your opensc.conf should look like this.
```
    cat opensc.conf
    app default {
        # debug = 3;
        # debug_file = opensc-debug.txt;
        card_drivers = cac
        force_card_driver = cac
        framework pkcs15 {	
        # use_file_caching = true;
        }
    }
```
\
Run opensc-tools -l again and your smartcard reader should be listed.
\
### Download DoD Certificates
This will put all of the certificates in ~/Documents/dod-certs/
```
cd Documents
wget https://militarycac.com/maccerts/AllCerts.zip
unzip AllCerts.zip -d dod-certs
```
\
### Firefox
Load security device (automatic)
```
pkcs11-register
```
\
### Chrome/ Chromium
\
**I highly recommend using ```ungoogled-chromium``` from the AUR and using that as your dedicated 'DoD' browser.\
\
Save bookmarks for Army Virtual Desktop, DoD Safe, etc...\
\
Regular Chrome/ Chromium has security shit that gets in the way. Additional configuration is required for those.**\
\
Add the CAC module to NSS DB.
This process may take a minute to figure its shit out.
```
modutil -dbdir sql:$HOME/.pki/nssdb/ -list
```
You should see something similar.
```
    Listing of PKCS #11 Modules
    -----------------------------------------------------------
    1. NSS Internal PKCS #11 Module
   	   uri: pkcs11:library-manufacturer=Mozilla%20Foundation;library-description=NSS%20Internal%20Crypto%20Services;library-version=3.61
   	 slots: 2 slots attached
   	status: loaded


    2. OpenSC smartcard framework (0.22)
	library name: /usr/lib/onepin-opensc-pkcs11.so
	   uri: pkcs11:library-manufacturer=OpenSC%20Project;library-description=OpenSC%20smartcard%20framework;library-version=0.22
```

### Import DoD Certificates
```
cd ~/Documents/dod-certs
for n in *.p7b; do certutil -d sql:$HOME/.pki/nssdb -A -t TC -n $n -i $n; done
for n in *.pem; do certutil -d sql:$HOME/.pki/nssdb -A -t TC -n $n -i $n; done
```
Verify the authority is in Chrome/ Chromium under Settings> Show Advanced> Manage Certificates> Authorities then expand "org-U.S. Government"
\
You should see a lot of "DoD" certificates listed.
\
### Setup Complete
\
Fuck you, Jeremy.

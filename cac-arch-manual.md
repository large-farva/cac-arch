## How to Use DoD CAC on Arch Linux

### Update and Install Required Packages

```bash
yay -Syu
yay -S ccid opensc pcsc-tools
```

Make sure `cackey` and `coolkey` are uninstalled:

```bash
yay -R cackey coolkey
sudo pacman -Rns
```

### Start and Enable the PCSC Daemon

```bash
sudo systemctl start pcscd
sudo systemctl enable pcscd
```

### Verify Your CAC Reader

Insert your CAC, remove it, and insert it again after running `pcsc_scan`. You should see the PCSC daemon reading your CAC in real-time.

```bash
pcsc_scan
```

**If There Are Errors:**

```bash
sudo systemctl restart pcscd.socket
sudo systemctl restart pcscd.service
```

If you see "scanning present readers waiting for the first reader...", unload the kernel modules:

```bash
modprobe -r pn533 nfc
```

### Verify Drivers

```bash
opensc-tools -l
```

You should see your smartcard reader listed. For example:

```
# Detected readers (pcsc)
Nr.  Card  Features  Name
0    Yes             Broadcom Corp 58200 [Contacted SmartCard] (0123456789ABCD) 00 00
```

If not, update `/etc/opensc/opensc.conf`:

```bash
card_drivers = cac
force_card_driver = cac
```

### Download DoD Certificates

This will download and extract DoD certificates:

```bash
cd ~/Documents
wget https://militarycac.com/maccerts/AllCerts.zip
unzip AllCerts.zip -d dod-certs
```

### Firefox: Load Security Device (Automatic)

```bash
pkcs11-register
```

### Chrome/Chromium

**I recommend using `ungoogled-chromium` from the AUR.** Regular Chrome/Chromium has additional security features that may interfere.

Add the CAC module to NSS DB:

```bash
modutil -dbdir sql:$HOME/.pki/nssdb/ -list
```

You should see something similar:

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

```bash
cd ~/Documents/dod-certs
for n in *.p7b; do certutil -d sql:$HOME/.pki/nssdb -A -t TC -n $n -i $n; done
for n in *.pem; do certutil -d sql:$HOME/.pki/nssdb -A -t TC -n $n -i $n; done
```

Verify the authority in Chrome/Chromium under:<br>
**Settings > Privacy and Security > Manage Certificates > Authorities**<br>
Expand "org-U.S. Government" to see the "DoD" certificates listed.

### Setup Complete

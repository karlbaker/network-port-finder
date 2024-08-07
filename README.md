# Network Port Finder

## Overview
The purpose of this script and associated to files is to create a small portable network device to identify the remote network device and it's associated port. This is done by leveraging the switch's Link Layer Discovery Protocol (LLDP) to provide that information.

## The Why
There are plenty of professional tools that can provide this type of service, but they tend to be expensive and in limited quantity within an organization. This provides a quick solution when you're in a pinch trying to trace down mislabeled or unlabeled ports in rooms or patch panels. 

## Build of Materials (BoM)

 - (1) [Raspberry Pi Zero](https://amzn.to/4d5CCtM)
 - (1) [32GB microSD](https://amzn.to/4f9ku40)
 - (1) [Pisugar2](https://amzn.to/3y4ljdR)
 - (1) [Waveshare 2.23 inch OLED Display HAT](https://amzn.to/4bOJ8Er)
 - (1) [Waveshare Ethernet/USB HUB HAT Expansion Board](https://amzn.to/3zHymCt)
 - (1) 3D Printed case (See STL folder)
 - (4) M2 4mm x 3.5mm Female Thread Knurled Nut - [This is the set I'm using](https://amzn.to/3Y3iiVF)
 - (4) M2x10 Screw - [This is the set I'm using](https://amzn.to/3y2eDNu)

## Software Requirements / Tested Baseline

*Note: Newer version of the listed software may work fine, but have not been tested.*
 **OS**
 - Raspbian GNU/Linux 11 (bullseye)"

**Packages**
 - lldpd v1.0.11
 - bmc2835 v1.71
 - Python v3.9.2
 - PiSugar Power Manager

## OS File Structure

Copy the lib and network-port-finder directories to the root of your filesystem.

```bash
├── /network-port-finder/
│   ├── network-port-finder.py
│   ├── 04B_08__.TTF
│   ├── lcdlib/
│   │   ├── config.py
│   │   ├── SSD1305.py
│   │   ├── __pycache__/
│   │   │   ├── config.cpython-39.pyc
│   │   │   ├── SSD1305.cpython-39.pyc
├── /lib/
│   ├── systemd/
│   │   ├── system/
│   │   │   ├── network-port-finder.service
```
## Installing the service
You can either run the `setup.sh` installation script or run through the manual setup that is outlined under the `Manual Installation` section on this README file.

To run through the installation script perform a git clone of this repo, navigate into the main directory then run `sudo ./setup` to kick off the installation.

- *Note: The PiSugar Power Manager is still a manual process, run through the prompts and reboot your Pi once complete. It is important that a reboot occurs to get SPI working.* 

## Manual Installation

There are a few packages that will need to be installed before starting the service. 

### **Link Layer Discovery Protocol (LLDP) agent daemon**

This daemon will pull the LLDP information from your infrastructure's network device. Use the following commands to install, start and enable the daemon at startup.
- `sudo apt-get install -y lldpd`

### **PiSugar Power Manager**

This script will load the PiSugar Power Manager that will provide a continuous status of the PiSugar's battery life. Use the following command to install and start the power manager.

- `curl http://cdn.pisugar.com/release/pisugar-power-manager.sh | sudo bash`

Installation Steps - You'll be prompted with several steps to setup the Power Manager application.

- Select the appropriate PiSugar 2 model (mine is the PiSugar 2-LED Version)
- Enter in the HTTP authentication username (not needed for our purpose but its a part of the installation).
- Enter in the HTTP authentication password 
- Press **[Enter]** at the **Configuring pisugar-server** prompt.
- Select the appropriate PiSugar 2 model at the **Configuring pisugar-poweroff** prompt. 
- PiSugar Power Manager installation will be complete at this point.

### **OLED Display Setup**

Run the following commands to setup the OLED display:

**Enable SPI Interface**

- `sudo raspi-config`
- `Choose Interfacing Options -> SPI -> Select <Yes> to enable`
- `sudo reboot` 

**Install BCM2835 Library**
- `wget http://www.airspayce.com/mikem/bcm2835/bcm2835-1.71.tar.gz`
- `tar zxvf bcm2835-1.71.tar.gz`
- `cd bcm2835-1.71/`
- `sudo ./configure && sudo make && sudo make check && sudo make install`

## Start Network Port Finder Service
The daemon would need to be reloaded using `sudo systemctl daemon-reload` command. 

Use the following commands to start and enable the service at start up.
- `sudo systemctl start network-port-finder.service`
- `sudo systemctl enable network-port-finder.service`

## LCD Display
When the daemon is started the LCD screen will display the port and battery status. 

There will be (3) different status types:

 1. **ETH0 NOT CONNECTED** - This indicates there is no network connection to the finder.
 ![ETH0 NOT CONNECTED Example Picture](https://i.imgur.com/yL0fxYP.jpeg)
 2. **NO LLDP INFORMATION AVAILABLE** - This indicates the finder's network port has a connection, but no LLDP information is being reported. This status usually occurs when finder is initializing the connection or the remote device has LLDP turned off or doesn't support it. 
![NO LLDP INFORMATION AVAILABLE Example Picture](https://i.imgur.com/nBBZ0Q4.jpeg)
 3. **LLDP Information w/ data** - This indicates the finder did pull the LLDP information from the remote device and will display remote device's MGMT IP, Hostname, and the connected port. 
 
 *Note: The text will scroll to the left if the LLDP information is too long for the screen (<=25 characters).*
![LLDP Information w/ data Example Picture](https://i.imgur.com/IZEL82G.jpeg)
## Network Port Finder Case - STL 3D Print Files

The design is fairly rudimentary. If I was to remake the case I would try to keep it with in the 1RU space (1.75") and shrink down the thickness of the case. 

- Lid: The (4) M2x10 Screw will be used to secure the lid to the base. Be careful: Tightening the screw too much will cause the nut to come out of the base.
- Base: The (4) M2 4mm x 3.5mm Female Thread Knurled Nut will be pushed into the cavities of the base. I used a heat source on the nut for the initial insertion then used a clamp to make the nut flush to the base.
- Slider: Use (1) M2x10 Screw to combine the two parts together. Insert 'Part B' into the inside and Part A will line up with Part B hole on the outside with the screw combining the two pieces. 

### Lid
![Network Port Finder Lid](https://i.imgur.com/6fla0HW.png)
### Base
![Network Port Finder Base](https://i.imgur.com/tbahiS0.png)

### Slider Switch

Part A

![Network Port Finder Slider Part A](https://i.imgur.com/Shx8q6A.png)

Part B

![Network Port Finder Slider Part B](https://i.imgur.com/jzfXXoq.png)

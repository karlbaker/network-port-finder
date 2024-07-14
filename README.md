# Network Port Finder

## Overview
The purpose of this script and associated to files is to create a small portable network device to identify a network port network switch and the switch's associated port. This is done by leveraging the switch's Link Layer Discovery Protocol (LLDP) to provide that information.

## The Why
There are plenty of professional tools that can provide this type of service, but they tend to be expensive and in limited quantity within an organization. This provides a quick solution when you're in a pinch trying to trace down mislabeled or unlabeled ports in rooms or patch panels. 

## Build of Materials (BoM)

 - (1) Raspberry Pi Zero 2 w/ Pre Soldered Header
 - (1) 32GB microSD
 - (1) Pisugar2
 - (1) Waveshare 2.23 inch OLED Display HAT
 - (1) Waveshare Ethernet/USB HUB HAT Expansion Board
 - (1) 3D Printed case (See STL folder)
 - (4) M2 4mm x 3.5mm Female Thread Knurled Nut
 - (4) M2x6 Screw

## Software Requirements / Tested Baseline
*Note: Newer version of the listed software may work fine, but have not been tested.*
 
 **OS**
 - Raspbian GNU/Linux 11 (bullseye)"

**Packages**
 - lldpad v0.5.7
 - bmc2835 v1.71 (included in repo)
 - Python v3.9.2
 - PiSugar Power Manager

## OS File Structure
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
## Preparing the OS
There are a few packages that will need to be installed before starting the service. 

**Link Layer Discovery Protocol (LLDP) agent daemon**
This daemon will pull the LLDP information from your infrastructure's network device. Use the following commands to install, start and enable the daemon at startup.
- `sudo apt-get install lldpad`
- `sudo systemctl start lldpad.service`
- `sudo systemctl enable lldpad.service`

**PiSugar Power Manager**
This script will load the PiSugar Power Manager that will provide a continuous status of the PiSugar's battery life. Use the following command to install and start the power manager.
- `curl http://cdn.pisugar.com/release/pisugar-power-manager.sh | sudo bash`

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
![LLDP Information w/ data Example Picture](https://i.imgur.com/IZEL82G.jpeg)
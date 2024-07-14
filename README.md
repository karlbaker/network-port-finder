# Network Port Finder

## Overview
The purpose of this script and associated to files is to create a small portable network device to identify a network port network switch and the switch's associated port. This is done by leveraging the switch's Link Layer Discovery Protocol (LLDP) to provide that information.

## The Why
There are plenty of professional tools that can provide this type of service, but they tend to be expensive and in limited quantity with organization that do use the retail devices. This provides a quick solution when you're in a pinch when tracing down mislabeled or unlabeled ports in rooms or patch panels. 

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
 - OS: Raspbian GNU/Linux 11 (bullseye)"
 - Packages:
 - [ ] lldpad v0.5.7
 - [ ] bmc2835 v1.71 (included in repo)
 - [ ] Python v3.9.2
 - [ ] PiSugar Power Manager

## File Structure
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

## Start Service
The daemon would need to be reloaded using `sudo systemctl daemon-reload` command. 

Use the following commands to start and enable the service at start up.
- `sudo systemctl start network-port-finder.service`
- `sudo systemctl enable network-port-finder.service`
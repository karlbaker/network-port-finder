#!/bin/bash

LOGFILE="/var/log/network_port_finder_setup.log"

log() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" | tee -a "$LOGFILE" > /dev/null
}

header() {
    log "Starting Network Port Finder Setup"
    echo "######################################################"
    echo "###            Network Port Finder Setup           ###"
    echo "######################################################"
    echo ""
}

footer() {
    log "Prompting user for PiSugar Power Manager installation"
    echo "The next package will require some user interaction to install the PiSugar Power Manager."
    echo "When the PiSugar Power Manager is installed, the Raspberry Pi will require a REBOOT."
    echo "Press [Enter] to continue with the PiSugar Power Manager install...."
    read
}

print_status() {
    local status=$1
    if [ "$status" == "PASS" ]; then
        echo -e "\e[32mPASS\e[0m]"  # Green color
        log "Status: PASS"
    elif [ "$status" == "FAIL" ]; then
        echo -e "\e[31mFAIL\e[0m]"  # Red color
        log "Status: FAIL"
        exit 1
    else
        echo -e "\e[31mINVALID\e[0m]"
        log "Status: Invalid"
    fi
}

check_network() {
    log "Checking network connection"
    echo -n "Verify there is a network connection.......["
    if curl -s --head http://www.google.com -o /dev/null -f; then
        print_status "PASS"
    else
        log "Network connection check failed"
        print_status "FAIL"
    fi
}

package_install() {
    local package=$1
    log "Updating package lists and installing package: $package"
    sudo apt update -y > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "Failed to update package lists"
        print_status "FAIL"
    fi

    sudo apt-get install -y $package > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "Package $package installed successfully"
        print_status "PASS"
    else
        log "Failed to install package $package"
        print_status "FAIL"
    fi
}

install_lldp() {
    log "Starting installation of LLDP package"
    echo -n "Installing LLDP package....................["
    package_install lldpd
}

enable_spi_interface() {
    CONFIG_FILE="/boot/config.txt"
    MODULES_FILE="/etc/modules"

    log "Enabling SPI interface"
    SPI_ENABLED=$(grep -c "^dtparam=spi=on" "$CONFIG_FILE")
    if [ $SPI_ENABLED -eq 0 ]; then
        log "Enabling SPI in $CONFIG_FILE"
        echo "dtparam=spi=on" | sudo tee -a "$CONFIG_FILE" > /dev/null
        if [ $? -ne 0 ]; then
            log "Failed to enable SPI in $CONFIG_FILE"
            print_status "FAIL"
        fi
        log "SPI enabled in $CONFIG_FILE"
    else
        log "SPI already enabled in $CONFIG_FILE"
    fi

    sudo modprobe spi-bcm2835
    if [ $? -ne 0 ]; then
        log "Failed to load SPI kernel module"
        print_status "FAIL"
    fi
    log "Loaded SPI kernel module"

    SPI_MODULE_ENABLED=$(grep -c "^spi-bcm2835" "$MODULES_FILE")
    if [ $SPI_MODULE_ENABLED -eq 0 ]; then
        log "Enabling SPI module in $MODULES_FILE"
        echo "spi-bcm2835" | sudo tee -a "$MODULES_FILE" > /dev/null
        if [ $? -ne 0 ]; then
            log "Failed to enable SPI module in $MODULES_FILE"
            print_status "FAIL"
        fi
        log "SPI module enabled in $MODULES_FILE"
    else
        log "SPI module already enabled in $MODULES_FILE"
    fi

    SPI_ENABLED=$(grep -c "^dtparam=spi=on" "$CONFIG_FILE")
    SPI_MODULE_ENABLED=$(grep -c "^spi-bcm2835" "$MODULES_FILE")
    if [ $SPI_ENABLED -ne 0 ] && [ $SPI_MODULE_ENABLED -ne 0 ]; then
        log "SPI enabled successfully"
        print_status "PASS"
    else
        log "Failed to enable SPI"
        print_status "FAIL"
    fi
}

install_bcm2835() {
    echo -n "Installing BCM2835 Library.................["
    log "Starting installation of BCM2835 Library"
    wget http://www.airspayce.com/mikem/bcm2835/bcm2835-1.71.tar.gz > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "Failed to download BCM2835 library"
        print_status "FAIL"
    fi
    log "Downloaded BCM2835 library"

    tar zxvf bcm2835-1.71.tar.gz > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "Failed to extract BCM2835 library"
        print_status "FAIL"
    fi

    cd bcm2835-1.71/
    sudo ./configure > /dev/null 2>&1 && sudo make > /dev/null 2>&1 && sudo make check > /dev/null 2>&1 && sudo make install > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "BCM2835 library installed successfully"
        print_status "PASS"
    else
        log "Failed to install BCM2835 library"
        print_status "FAIL"
    fi

    cd ..
    rm -rf bcm2835-1.71/ bcm2835-1.71.tar.gz
    log "Cleaned up BCM2835 installation files"
}

install_ppm() {
    log "Installing PiSugar Power Manager"
    curl http://cdn.pisugar.com/release/pisugar-power-manager.sh | sudo bash
    if [ $? -ne 0 ]; then
        log "Failed to install PiSugar Power Manager"
        print_status "FAIL"
    fi
}

enable_npf_service() {
    log "Enabling Network Port Finder service"
    echo -n "Copying application to the root directory..["
    if cp -r network-port-finder /; then 
        log "Application copied to root directory"
        print_status "PASS"
    else
        log "Failed to copy application to root directory"
        print_status "FAIL"
    fi
    
    echo -n "Creating the Network Port Finder service...["
    if cp lib/systemd/system/network-port-finder.service /lib/systemd/system/.; then
        log "Service file copied successfully"
        print_status "PASS"
    else
        log "Failed to copy service file"
        print_status "FAIL"
    fi

    echo -n "Reloading systemctl daemon.................["
    if systemctl daemon-reload; then
        log "Systemctl daemon reloaded"
        print_status "PASS"
    else
        log "Failed to reload systemctl daemon"
        print_status "FAIL"
    fi

    echo -n "Enabling the Network Port Finder service...["
    if systemctl enable network-port-finder.service > /dev/null 2>&1; then
        log "Network Port Finder service enabled"
        print_status "PASS"
    else
        log "Failed to enable Network Port Finder service"
        print_status "FAIL"
    fi
}

######################################################
###             Where the magic happens            ###
######################################################

header
check_network
install_lldp
install_bcm2835
enable_spi_interface
enable_npf_service
footer
install_ppm

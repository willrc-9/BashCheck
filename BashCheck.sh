#!/usr/bin/env bash

# Script for basic IT support, inspired by Jahir Hussain on LinkedIn
# Specifically for RHEL derivitives, ie Fedora, CentOS, Rocky, etc.

# Information in Jahir's LinkedIn Windows Tool:
# System Info, SFC Scan, SFC Verify Only
# DISM Scan Health & DISM Repair (RestoreHealth)
# Component Store Cleanup
# Drive Health (SMART)
# Flush DNS & Reset Winsock
# Reset TCP/IP
# Battery Report & Performance Report
# WinRE Info & Advanced Startup
# System Restore & Memory Diagnostic
# Check Windows Update
# Full Report (All Info)
# Disk Cleanup
# Event Log Errors (Last 20) 

RED='\033[0;31m'; GREEN='\033[32m'; CYAN='\033[36m'; NC='\033[0m'

CYANTEXT(){
	echo -e "${CYAN}$1${NC}"
}

GREENTEXT(){
	echo -e "${GREEN}$1${NC}"
}

REDTEXT(){
	echo -e "${RED}$1${NC}"
}

if [ "$EUID" -ne 0 ]; then
	echo -e "${RED}[-] Please run this script with sudo/root privileges ($ sudo -i)${NC}"
	exit 1
fi


showMenu(){
	clear
	CYANTEXT "==========================================================="
	CYANTEXT "===							==="
	CYANTEXT "=== BachCheck - Simple Linux Diagnostic and Repair Tool ==="
	CYANTEXT "===            Written by William Collison              ==="
	CYANTEXT "===							==="
	CYANTEXT "==========================================================="
	echo ""
	echo " 1) System Information & Performance"
	echo " 2) System Files (File Integrity)"
	echo " 3) Package/Repo Health & Repair"
	echo " 4) Cache and Junk File Cleanup"
	echo " 5) Storage Health (SMART)"
	echo " 6) Flush DNS & Reset Network"
	echo " 7) Check for Software Updates"
	echo " 8) Disk Cleanup & Cache Purge"
	echo " 9) Recent System Errors (tail 20)"
	echo "10) Full Diagnostic Report"
	echo " 0) Exit"
	echo ""
	read -p "Select an option [1-10): " choice
}

exitCase=0

while [[ exitCase != 1 ]]; do
	showMenu
	case $choice in
		1) # System Information & Performance
			CYANTEXT "--- System Information & Performance ---"
			hostnamectl
			echo ""
			lscpu | grep "Model name"
			free -h
			uptime
			;;
		
		2) # System Files (File Integrity)
			CYANTEXT "--- System Files (Verify File Integrity"
			rpm -Va
			;;

		3) # Package/Repo Health & Repair
			CYANTEXT "--- Checking Repository Health ---"
			dnf check
			;;
		4) # Cache and Junk File Cleanup
			CYANTEXT "--- Clearing DNF Cache and Unneeded Dependencies ---"
			dnf clean all
			dnf autoremove -y
			;;
		5) # Storage Health (SMART)
			CYANTEXT "--- Checking Drive Health (SMART) ---"
			if ! command -v smartctl &> /dev/null; then
				echo "smartmontools not found. Installing..."
				dnf install -y smartmontools
			fi

			PRIMARY_DISK=$(lsblk -d -o NAME,TYPE | grep disk | head -n 1 | awk '{print "/dev/" $1}')
			smartctl -H "$PRIMARY_DISK"
			;;
		6) # Flush DNS & Reset Network
			CYANTEXT "--- Flushing DNS and Restarting NetworkManager ---"
			resolvectl flush-caches
			systemctl restart NetworkManager
			GREENTEXT "[+] Cleanup complete."
			;;
		7) # Check for Software Updates
			CYANTEXT "--- Checking for Updates ---"
			dnf check-update
			;;
		8) # Disk Cleanup & Cache Purge
			CYANTEXT "--- Performing Deep Disk Cleanup & Cache Purge ---"
			journalctl --vacuum-time=7d
			rm -rf /tmp/* /var/tmp/*
			GREENTEXT "[+] Cleanup complete."
			;;
		9) # Recent System Errors (tail 20)
			CYANTEXT "--- Last 20 System Errors (tail 20) ---"
			journalctl -p err -n 20 --no-pager
			;;
		10) # Full Diagnostic Report
			CYANTEXT "--- Generating a Full Diagnostic Report ---"
			hostnamectl
			echo "--- Memory & Uptime ---"
			free -h && uptime
			echo "--- Recent Errors ---"
			journalctl -p err -n 5 --no-pager
			;;
		0) # Exit
			echo "Exiting..."
			exit 0
			;;
		*)
			REDTEXT "Invalid Option. Please choose between 0 and 10."
			;;
	esac
	read -p "Press [Enter] to continue..."
done

